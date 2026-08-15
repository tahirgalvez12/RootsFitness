import SwiftUI

/// Shown when the app is opened via the password-reset deep link
/// (`rootsfitness://reset-password`, see `RootView.onOpenURL`). The link's
/// session has already been established by that point — this view only
/// collects the new password and applies it.
struct ResetPasswordView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var didSucceed = false

    private var canSubmit: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                if didSucceed {
                    successState
                } else {
                    formState
                }
            }
            .navigationTitle("New Password")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var formState: some View {
        VStack(spacing: 20) {
            Text("Choose a new password for your account.")
                .font(.rfBody)
                .foregroundStyle(Color.rfTextSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                RFTextField(
                    title: "New password (min 6 characters)",
                    text: $newPassword,
                    isSecure: true,
                    textContentType: .newPassword
                )

                RFTextField(
                    title: "Confirm password",
                    text: $confirmPassword,
                    isSecure: true,
                    textContentType: .newPassword
                )
            }

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.rfCaption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            } else if !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Passwords don't match")
                    .font(.rfCaption)
                    .foregroundStyle(.red)
            }

            RFPrimaryButton(
                title: "Update Password",
                isLoading: authViewModel.isLoading,
                isDisabled: !canSubmit
            ) {
                Task {
                    if await authViewModel.updatePassword(newPassword) {
                        didSucceed = true
                    }
                }
            }
        }
        .padding(.horizontal, RFMetrics.screenPadding)
        .padding(.top, 24)
    }

    private var successState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.rfAccent)

            Text("Password updated")
                .font(.rfLargeTitle)
                .foregroundStyle(Color.rfTextPrimary)

            Text("You're all set. Continue into RootsFitness.")
                .font(.rfBody)
                .foregroundStyle(Color.rfTextSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            RFPrimaryButton(title: "Continue", isLoading: false, isDisabled: false) {
                dismiss()
            }

            Spacer()
        }
        .padding(.horizontal, RFMetrics.screenPadding)
    }
}

#Preview {
    ResetPasswordView()
        .environment(AuthViewModel())
}
