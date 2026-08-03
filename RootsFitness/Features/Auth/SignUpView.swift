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
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("RootsFitness")
                    .font(.largeTitle.bold())
                Text("Create an account")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                TextField("Username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                SecureField("Password (min 6 characters)", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }

            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await authViewModel.signUp(email: email, password: password, username: username) }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit || authViewModel.isLoading)

            Button("Already have an account? Log In") {
                showLogIn = true
            }
            .font(.footnote)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    SignUpView(showLogIn: .constant(false))
        .environment(AuthViewModel())
}
