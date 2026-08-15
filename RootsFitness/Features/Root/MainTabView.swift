import SwiftUI

struct MainTabView: View {
    let currentUserID: UUID

    var body: some View {
        TabView {
            Tab("Feed", systemImage: "figure.run") {
                FeedView(viewModel: PostsViewModel(currentUserID: currentUserID))
            }
            Tab("Friends", systemImage: "person.2") {
                FriendsListView(viewModel: FriendsViewModel(currentUserID: currentUserID))
            }
            Tab("Settings", systemImage: "gearshape") {
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
