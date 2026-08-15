import Auth
import SwiftUI

struct RootView: View {
    @State private var authViewModel = AuthViewModel()
    @State private var showLogIn = true
    @State private var showResetPassword = false

    var body: some View {
        Group {
            switch authViewModel.state {
            case .signedOut:
                if showLogIn {
                    LogInView(showLogIn: $showLogIn)
                } else {
                    SignUpView(showLogIn: $showLogIn)
                }
            case .signedIn(let user):
                MainTabView(currentUserID: user.id)
            }
        }
        .environment(authViewModel)
        .task {
            authViewModel.start()
        }
        .onOpenURL { url in
            guard url.host == "reset-password" else { return }
            Task {
                await authViewModel.handleAuthDeepLink(url)
                showResetPassword = true
            }
        }
        .fullScreenCover(isPresented: $showResetPassword) {
            ResetPasswordView()
                .environment(authViewModel)
        }
    }
}

#Preview {
    RootView()
}
