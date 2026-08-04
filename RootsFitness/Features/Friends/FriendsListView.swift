import SwiftUI

struct FriendsListView: View {
    @State var viewModel: FriendsViewModel
    @State private var showAddFriend = false

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if !viewModel.incomingRequests.isEmpty {
                    Section("Requests") {
                        ForEach(viewModel.incomingRequests) { request in
                            HStack {
                                Text(request.requester.username)
                                Spacer()
                                Button("Accept") {
                                    Task { await viewModel.accept(request) }
                                }
                                .buttonStyle(.borderedProminent)
                                Button("Decline") {
                                    Task { await viewModel.decline(request) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                Section("Friends") {
                    if viewModel.friends.isEmpty {
                        Text("No friends yet. Tap + to add one.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.friends) { friend in
                            Text(friend.username)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let friend = viewModel.friends[index]
                                Task { await viewModel.removeFriend(friend) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddFriend = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                AddFriendView(viewModel: viewModel)
            }
            .task {
                await viewModel.refresh()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading && viewModel.friends.isEmpty && viewModel.incomingRequests.isEmpty {
                    ProgressView()
                }
            }
        }
    }
}

#Preview {
    FriendsListView(viewModel: FriendsViewModel(currentUserID: UUID()))
}
