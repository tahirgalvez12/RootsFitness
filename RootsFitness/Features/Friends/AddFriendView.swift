import SwiftUI

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: FriendsViewModel

    @State private var query = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.rfCaption)
                                .foregroundStyle(.red)
                        }

                        ForEach(viewModel.searchResults) { profile in
                            SearchResultRow(profile: profile, viewModel: viewModel)
                        }

                        if viewModel.isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if !query.isEmpty && viewModel.searchResults.isEmpty {
                            Text("No users found")
                                .font(.rfBody)
                                .foregroundStyle(Color.rfTextSecondary)
                        }
                    }
                    .padding(RFMetrics.screenPadding)
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

private struct SearchResultRow: View {
    let profile: Profile
    let viewModel: FriendsViewModel

    var body: some View {
        RFCard(padding: 14) {
            HStack(spacing: 12) {
                RFAvatar(username: profile.username, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.username)
                        .font(.rfHeadline)
                        .foregroundStyle(Color.rfTextPrimary)
                    if let displayName = profile.displayName {
                        Text(displayName)
                            .font(.rfCaption)
                            .foregroundStyle(Color.rfTextSecondary)
                    }
                }
                Spacer()
                if viewModel.sentRequestIDs.contains(profile.id) {
                    Text("Sent")
                        .font(.rfCaption)
                        .foregroundStyle(Color.rfTextSecondary)
                } else {
                    RFCompactButton(title: "Add") {
                        Task { await viewModel.sendRequest(to: profile) }
                    }
                }
            }
        }
    }
}

#Preview {
    AddFriendView(viewModel: FriendsViewModel(currentUserID: UUID()))
}
