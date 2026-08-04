import SwiftUI

struct MainTabView: View {
    let currentUserID: UUID

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "figure.run") {
                FeedView(viewModel: PostsViewModel(currentUserID: currentUserID))
            }
            Tab("Goals", systemImage: "target") {
                GoalsView(viewModel: GoalsViewModel(currentUserID: currentUserID))
            }
            Tab("Friends", systemImage: "person.2") {
                FriendsListView(viewModel: FriendsViewModel(currentUserID: currentUserID))
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                ProfilePlaceholderView()
            }
        }
    }
}

private struct ProfilePlaceholderView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        NavigationStack {
            List {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView(currentUserID: UUID())
        .environment(AuthViewModel())
}
