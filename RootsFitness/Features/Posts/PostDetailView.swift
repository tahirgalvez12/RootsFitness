import SwiftUI

struct PostDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let item: FeedItem
    let signedURLs: [UUID: URL]
    @State private var viewModel: PostDetailViewModel
    @State private var commentText = ""
    @FocusState private var isCommentFieldFocused: Bool

    init(item: FeedItem, signedURLs: [UUID: URL], currentUserID: UUID, initialReactions: [PostReaction]) {
        self.item = item
        self.signedURLs = signedURLs
        _viewModel = State(
            initialValue: PostDetailViewModel(
                postID: item.post.id,
                currentUserID: currentUserID,
                initialReactions: initialReactions
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            RFCard {
                                PostSummaryView(item: item, signedURLs: signedURLs)
                            }

                            sectionLabel("React")
                            RFReactionBar(
                                reactions: viewModel.reactions,
                                currentUserID: viewModel.currentUserID,
                                showAllKinds: true
                            ) { kind in
                                Task { await viewModel.toggleReaction(kind) }
                            }

                            sectionLabel("Comments")
                            if viewModel.comments.isEmpty && !viewModel.isLoading {
                                Text("No comments yet. Be the first to say something.")
                                    .font(.rfBody)
                                    .foregroundStyle(Color.rfTextSecondary)
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(viewModel.comments) { comment in
                                        RFCommentRow(comment: comment)
                                    }
                                }
                            }

                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.rfCaption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(RFMetrics.screenPadding)
                    }

                    commentInputBar
                }
            }
            .navigationTitle("Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                await viewModel.refresh()
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.rfCaption)
            .foregroundStyle(Color.rfTextSecondary)
    }

    private var commentInputBar: some View {
        HStack(spacing: 10) {
            TextField("Add a comment…", text: $commentText, axis: .vertical)
                .font(.rfBody)
                .focused($isCommentFieldFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                        .fill(Color.rfSurfaceElevated)
                )

            Button {
                let text = commentText
                commentText = ""
                Task { await viewModel.addComment(body: text) }
            } label: {
                if viewModel.isPosting {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(
                            commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? Color.rfTextSecondary.opacity(0.4)
                                : Color.rfAccent
                        )
                }
            }
            .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isPosting)
        }
        .padding(RFMetrics.screenPadding)
        .background(Color.rfSurfacePrimary)
    }
}
