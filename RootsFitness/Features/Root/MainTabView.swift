import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Feed", systemImage: "figure.run") {
                FeedPlaceholderView()
            }
            Tab("Goals", systemImage: "target") {
                GoalsPlaceholderView()
            }
            Tab("Profile", systemImage: "person.crop.circle") {
                ProfilePlaceholderView()
            }
        }
    }
}

private struct FeedPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No Posts Yet",
                systemImage: "figure.run",
                description: Text("Friends' workouts, meals, and progress will show up here.")
            )
            .navigationTitle("Feed")
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
    MainTabView()
        .environment(AuthViewModel())
}
