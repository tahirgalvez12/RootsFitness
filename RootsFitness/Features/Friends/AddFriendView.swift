import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FriendsViewModel

    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                ForEach(viewModel.searchResults) { profile in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(profile.username)
                                .font(.body)
                            if let displayName = profile.displayName {
                                Text(displayName)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if viewModel.sentRequestIDs.contains(profile.id) {
                            Text("Sent")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        } else {
                            Button("Add") {
                                Task { await viewModel.sendRequest(to: profile) }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else if !query.isEmpty && viewModel.searchResults.isEmpty {
                    Text("No users found")
                        .foregroundStyle(.secondary)
                }
            }
            .searchable(text: $query, prompt: "Search by username")
            .onChange(of: query) { _, newValue in
                Task { await viewModel.search(username: newValue) }
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AddFriendView(viewModel: FriendsViewModel(currentUserID: UUID()))
}
