import SwiftUI

struct LogInView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Binding var showLogIn: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var showForgotPassword = false

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

                Button("Forgot password?") {
                    showForgotPassword = true
                }
                .font(.rfSubheadline)
                .foregroundStyle(Color.rfAccent)
                .frame(maxWidth: .infinity, alignment: .trailing)

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
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var didSend = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                if didSend {
                    confirmationState
                } else {
                    formState
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var formState: some View {
        VStack(spacing: 20) {
            Text("Enter your email and we'll send you a link to reset your password.")
                .font(.rfBody)
                .foregroundStyle(Color.rfTextSecondary)
                .multilineTextAlignment(.center)

            RFTextField(
                title: "Email",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: false
            )

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.rfCaption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            RFPrimaryButton(
                title: "Send Reset Link",
                isLoading: authViewModel.isLoading,
                isDisabled: email.isEmpty
            ) {
                Task {
                    if await authViewModel.sendPasswordReset(email: email) {
                        didSend = true
                    }
                }
            }
        }
        .padding(.horizontal, RFMetrics.screenPadding)
        .padding(.top, 24)
    }

    private var confirmationState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.rfAccent)

            Text("Check your email")
                .font(.rfLargeTitle)
                .foregroundStyle(Color.rfTextPrimary)

            Text("We sent a password reset link to \(email). Tap it to set a new password.")
                .font(.rfBody)
                .foregroundStyle(Color.rfTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)

            Spacer()

            RFPrimaryButton(title: "Done", isLoading: false, isDisabled: false) {
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, RFMetrics.screenPadding)
    }
}

#Preview {
    LogInView(showLogIn: .constant(true))
        .environment(AuthViewModel())
}
