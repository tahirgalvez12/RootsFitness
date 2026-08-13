import Foundation
import Supabase

struct CommentWithAuthor: Identifiable, Hashable {
    let comment: PostComment
    let author: Profile?
    var id: UUID { comment.id }
}

/// Owns the full comment list + reactions for a single post — kept separate
/// from PostsViewModel so opening a post detail doesn't force a full feed
/// re-fetch, matching how HealthSyncViewModel is its own small view model.
@MainActor
@Observable
final class PostDetailViewModel {
    let postID: UUID
    let currentUserID: UUID

    private(set) var comments: [CommentWithAuthor] = []
    private(set) var reactions: [PostReaction] = []

    var errorMessage: String?
    var isLoading = false
    var isPosting = false

    private let client = SupabaseClient.shared

    init(postID: UUID, currentUserID: UUID, initialReactions: [PostReaction]) {
        self.postID = postID
        self.currentUserID = currentUserID
        self.reactions = initialReactions
    }

    func refresh() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            async let commentsTask: [PostComment] = client
                .from("post_comments")
                .select()
                .eq("post_id", value: postID)
                .order("created_at", ascending: true)
                .execute()
                .value

            async let reactionsTask: [PostReaction] = client
                .from("post_reactions")
                .select()
                .eq("post_id", value: postID)
                .execute()
                .value

            let (fetchedComments, fetchedReactions) = try await (commentsTask, reactionsTask)
            reactions = fetchedReactions

            let authorIDs = Array(Set(fetchedComments.map(\.userID)))
            let authors: [Profile] = authorIDs.isEmpty ? [] : try await client
                .from("profiles")
                .select()
                .in("id", values: authorIDs)
                .execute()
                .value
            let authorByID = Dictionary(uniqueKeysWithValues: authors.map { ($0.id, $0) })

            comments = fetchedComments.map { comment in
                CommentWithAuthor(comment: comment, author: authorByID[comment.userID])
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(body: String) async {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isPosting = true
        defer { isPosting = false }
        do {
            try await client.from("post_comments").insert(
                NewCommentRow(postID: postID, userID: currentUserID, body: trimmed)
            ).execute()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleReaction(_ kind: ReactionKind) async {
        let existing = reactions.first { $0.userID == currentUserID && $0.reaction == kind }
        do {
            if let existing {
                try await client
                    .from("post_reactions")
                    .delete()
                    .eq("id", value: existing.id)
                    .execute()
                reactions.removeAll { $0.id == existing.id }
            } else {
                let inserted: PostReaction = try await client
                    .from("post_reactions")
                    .insert(NewReactionRow(postID: postID, userID: currentUserID, reaction: kind))
                    .select()
                    .single()
                    .execute()
                    .value
                reactions.append(inserted)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct NewCommentRow: Encodable {
    let postID: UUID
    let userID: UUID
    let body: String

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case userID = "user_id"
        case body
    }
}

private struct NewReactionRow: Encodable {
    let postID: UUID
    let userID: UUID
    let reaction: ReactionKind

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case userID = "user_id"
        case reaction
    }
}
