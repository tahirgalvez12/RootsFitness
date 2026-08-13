import SwiftUI

struct LogInView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Binding var showLogIn: Bool

    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty
    }

    var body: some View {
        ZStack {
            RFBackground()

            VStack(spacing: 28) {
                Spacer(minLength: 24)

                VStack(spacing: 6) {
                    Text("RootsFitness")
                        .font(.rfDisplay)
                        .foregroundStyle(Color.rfTextPrimary)
                    Text("Welcome back")
                        .font(.rfBody)
                        .foregroundStyle(Color.rfTextSecondary)
                }

                VStack(spacing: 12) {
                    RFTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: false
                    )

                    RFTextField(
                        title: "Password",
                        text: $password,
                        isSecure: true,
                        textContentType: .password
                    )
                }

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.rfCaption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                RFPrimaryButton(
                    title: "Log In",
                    isLoading: authViewModel.isLoading,
                    isDisabled: !canSubmit
                ) {
                    Task { await authViewModel.signIn(email: email, password: password) }
                }

                Button("Don't have an account? Sign Up") {
                    showLogIn = false
                }
                .font(.rfSubheadline)
                .foregroundStyle(Color.rfAccent)

                Spacer()
            }
            .padding(.horizontal, RFMetrics.screenPadding)
        }
    }
}

#Preview {
    LogInView(showLogIn: .constant(true))
        .environment(AuthViewModel())
}
