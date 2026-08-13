import SwiftUI

struct SignUpView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Binding var showLogIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && !username.isEmpty
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
                    Text("Create an account")
                        .font(.rfBody)
                        .foregroundStyle(Color.rfTextSecondary)
                }

                VStack(spacing: 12) {
                    RFTextField(
                        title: "Username",
                        text: $username,
                        textContentType: .username,
                        autocapitalization: false
                    )

                    RFTextField(
                        title: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: false
                    )

                    RFTextField(
                        title: "Password (min 6 characters)",
                        text: $password,
                        isSecure: true,
                        textContentType: .newPassword
                    )
                }

                if let errorMessage = authViewModel.errorMessage {
                    Text(errorMessage)
                        .font(.rfCaption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                RFPrimaryButton(
                    title: "Sign Up",
                    isLoading: authViewModel.isLoading,
                    isDisabled: !canSubmit
                ) {
                    Task { await authViewModel.signUp(email: email, password: password, username: username) }
                }

                Button("Already have an account? Log In") {
                    showLogIn = true
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
    SignUpView(showLogIn: .constant(false))
        .environment(AuthViewModel())
}
