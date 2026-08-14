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

            if authViewModel.awaitingEmailConfirmation {
                confirmEmailNotice
            } else {
                signUpForm
            }
        }
    }

    private var signUpForm: some View {
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

    private var confirmEmailNotice: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.rfAccent)

            Text("Check your email")
                .font(.rfLargeTitle)
                .foregroundStyle(Color.rfTextPrimary)

            Text("We sent a confirmation link to \(email). Tap it, then come back and log in.")
                .font(.rfBody)
                .foregroundStyle(Color.rfTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Spacer()

            RFPrimaryButton(title: "Back to Log In", isLoading: false, isDisabled: false) {
                authViewModel.acknowledgeEmailConfirmationNotice()
                showLogIn = true
            }

            Spacer()
        }
        .padding(.horizontal, RFMetrics.screenPadding)
    }
}

#Preview {
    SignUpView(showLogIn: .constant(false))
        .environment(AuthViewModel())
}
