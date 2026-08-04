import SwiftUI

struct MainTabView: View {
    let currentUserID: UUID

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "figure.run") {
                FeedView(viewModel: PostsViewModel(currentUserID: currentUserID))
            }
            Tab("Goals", systemImage: "target") {
                GoalsPlaceholderView()
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

private struct GoalsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Goals Set",
                systemImage: "target",
                description: Text("Set a goal like losing weight, bulking, or general fitness.")
            )
            .navigationTitle("Goals")
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
