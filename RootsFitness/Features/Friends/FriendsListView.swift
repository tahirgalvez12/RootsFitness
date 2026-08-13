import SwiftUI

struct FriendsListView: View {
    @State var viewModel: FriendsViewModel
    @State private var showAddFriend = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                if viewModel.isLoading && viewModel.friends.isEmpty && viewModel.incomingRequests.isEmpty {
                    ProgressView()
                } else if viewModel.friends.isEmpty && viewModel.incomingRequests.isEmpty {
                    RFEmptyState(
                        icon: "person.2.fill",
                        title: "No Friends Yet",
                        message: "Add friends by username to start sharing your fitness journey.",
                        actionTitle: "Add a Friend"
                    ) {
                        showAddFriend = true
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.rfCaption)
                                    .foregroundStyle(.red)
                            }

                            if !viewModel.incomingRequests.isEmpty {
                                sectionLabel("Requests")
                                VStack(spacing: 10) {
                                    ForEach(viewModel.incomingRequests) { request in
                                        RequestRow(request: request, viewModel: viewModel)
                                    }
                                }
                            }

                            sectionLabel("Friends")
                            if viewModel.friends.isEmpty {
                                Text("No friends yet. Tap + to add one.")
                                    .font(.rfBody)
                                    .foregroundStyle(Color.rfTextSecondary)
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(viewModel.friends) { friend in
                                        FriendRow(friend: friend) {
                                            Task { await viewModel.removeFriend(friend) }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(RFMetrics.screenPadding)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus.fill")
                            .foregroundStyle(Color.rfAccent)
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView(viewModel: viewModel)
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
}

private struct RequestRow: View {
    let request: IncomingRequest
    let viewModel: FriendsViewModel

    var body: some View {
        RFCard(padding: 14) {
            HStack(spacing: 12) {
                RFAvatar(username: request.requester.username, size: 44)
                Text(request.requester.username)
                    .font(.rfHeadline)
                    .foregroundStyle(Color.rfTextPrimary)
                Spacer()
                RFCompactButton(title: "Decline", isFilled: false, role: .destructive) {
                    Task { await viewModel.decline(request) }
                }
                RFCompactButton(title: "Accept") {
                    Task { await viewModel.accept(request) }
                }
            }
        }
    }
}

private struct FriendRow: View {
    let friend: Profile
    let onRemove: () -> Void
    @State private var showRemoveConfirm = false

    var body: some View {
        RFCard(padding: 14) {
            HStack(spacing: 12) {
                RFAvatar(username: friend.username, size: 44)
                Text(friend.username)
                    .font(.rfHeadline)
                    .foregroundStyle(Color.rfTextPrimary)
                Spacer()
                Button {
                    showRemoveConfirm = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.rfTextSecondary.opacity(0.5))
                }
            }
        }
        .confirmationDialog(
            "Remove \(friend.username)?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove Friend", role: .destructive, action: onRemove)
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    FriendsListView(viewModel: FriendsViewModel(currentUserID: UUID()))
}
