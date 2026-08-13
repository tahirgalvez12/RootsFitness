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
                ProfileView(currentUserID: currentUserID)
            }
        }
        .tint(Color.rfAccent)
    }
}

#Preview {
    MainTabView(currentUserID: UUID())
        .environment(AuthViewModel())
}
