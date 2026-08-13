import Foundation
import Supabase

struct IncomingRequest: Identifiable, Hashable {
    let requester: Profile
    var id: UUID { requester.id }
}

@MainActor
@Observable
final class FriendsViewModel {
    private(set) var friends: [Profile] = []
    private(set) var incomingRequests: [IncomingRequest] = []
    private(set) var searchResults: [Profile] = []
    private(set) var sentRequestIDs: Set<UUID> = []

    var errorMessage: String?
    var isLoading = false
    var isSearching = false

    private let client = SupabaseClient.shared
    private let currentUserID: UUID

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
    }

    func refresh() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            async let friendshipsTask: [Friendship] = client
                .from("friendships")
                .select()
                .eq("user_id", value: currentUserID)
                .eq("status", value: FriendshipStatus.accepted.rawValue)
                .execute()
                .value

            async let incomingTask: [Friendship] = client
                .from("friendships")
                .select()
                .eq("friend_id", value: currentUserID)
                .eq("status", value: FriendshipStatus.pending.rawValue)
                .execute()
                .value

            let (accepted, incoming) = try await (friendshipsTask, incomingTask)

            let friendIDs = accepted.map(\.friendID)
            let requesterIDs = incoming.map(\.userID)

            async let friendProfilesTask: [Profile] = friendIDs.isEmpty ? [] : client
                .from("profiles")
                .select()
                .in("id", values: friendIDs)
                .execute()
                .value

            async let requesterProfilesTask: [Profile] = requesterIDs.isEmpty ? [] : client
                .from("profiles")
                .select()
                .in("id", values: requesterIDs)
                .execute()
                .value

            let (friendProfiles, requesterProfiles) = try await (friendProfilesTask, requesterProfilesTask)

            friends = friendProfiles.sorted { $0.username < $1.username }
            incomingRequests = requesterProfiles
                .map(IncomingRequest.init)
                .sorted { $0.requester.username < $1.requester.username }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search(username: String) async {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            return
        }
        errorMessage = nil
        isSearching = true
        defer { isSearching = false }
        do {
            let results: [Profile] = try await client
                .from("profiles")
                .select()
                .ilike("username", pattern: "%\(trimmed)%")
                .neq("id", value: currentUserID)
                .limit(20)
                .execute()
                .value
            searchResults = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(to target: Profile) async {
        errorMessage = nil
        do {
            try await client.from("friendships").insert(
                Friendship(
                    userID: currentUserID,
                    friendID: target.id,
                    status: .pending,
                    createdAt: Date()
                )
            ).execute()
            sentRequestIDs.insert(target.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ request: IncomingRequest) async {
        errorMessage = nil
        do {
            try await client.rpc(
                "accept_friend_request",
                params: ["requester": request.requester.id]
            ).execute()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func decline(_ request: IncomingRequest) async {
        errorMessage = nil
        do {
            try await client
                .from("friendships")
                .delete()
                .eq("user_id", value: request.requester.id)
                .eq("friend_id", value: currentUserID)
                .execute()
            incomingRequests.removeAll { $0.id == request.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeFriend(_ friend: Profile) async {
        errorMessage = nil
        do {
            try await client
                .from("friendships")
                .delete()
                .eq("user_id", value: currentUserID)
                .eq("friend_id", value: friend.id)
                .execute()
            try await client
                .from("friendships")
                .delete()
                .eq("user_id", value: friend.id)
                .eq("friend_id", value: currentUserID)
                .execute()
            friends.removeAll { $0.id == friend.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
