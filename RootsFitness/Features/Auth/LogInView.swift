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
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("RootsFitness")
                    .font(.largeTitle.bold())
                Text("Welcome back")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))

                SecureField("Password", text: $password)
                    .textContentType(.password)
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
                Task { await authViewModel.signIn(email: email, password: password) }
            } label: {
                if authViewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Log In")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canSubmit || authViewModel.isLoading)

            Button("Don't have an account? Sign Up") {
                showLogIn = false
            }
            .font(.footnote)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    LogInView(showLogIn: .constant(true))
        .environment(AuthViewModel())
}
