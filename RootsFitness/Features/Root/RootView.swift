import SwiftUI

struct RootView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var showLogIn = true

    var body: some View {
        Group {
            switch authViewModel.state {
            case .signedOut:
                if showLogIn {
                    LogInView(showLogIn: $showLogIn)
                } else {
                    SignUpView(showLogIn: $showLogIn)
                }
            case .signedIn:
                MainTabView()
            }
        }
        .environment(authViewModel)
        .task {
            authViewModel.start()
        }
    }
}

#Preview {
    RootView()
}
