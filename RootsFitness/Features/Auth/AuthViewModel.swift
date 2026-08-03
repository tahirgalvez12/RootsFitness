import Foundation
import Supabase

enum AuthState {
    case signedOut
    case signedIn(User)
}

@MainActor
@Observable
final class AuthViewModel {
    private(set) var state: AuthState = .signedOut
    var errorMessage: String?
    var isLoading = false

    private let client = SupabaseClient.shared
    private var authListenerTask: Task<Void, Never>?

    func start() {
        authListenerTask?.cancel()
        authListenerTask = Task {
            for await (event, session) in client.auth.authStateChanges {
                guard event == .initialSession || event == .signedIn || event == .signedOut else {
                    continue
                }
                if let session {
                    state = .signedIn(session.user)
                    await ensureProfileExists(for: session.user)
                } else {
                    state = .signedOut
                }
            }
        }
    }

    func signUp(email: String, password: String, username: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await client.auth.signUp(email: email, password: password)
            try await client.from("profiles").insert(
                Profile(
                    id: result.user.id,
                    username: username,
                    displayName: nil,
                    avatarURL: nil,
                    createdAt: Date()
                )
            ).execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await client.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func ensureProfileExists(for user: User) async {
        do {
            let existing: [Profile] = try await client
                .from("profiles")
                .select()
                .eq("id", value: user.id)
                .execute()
                .value
            if existing.isEmpty {
                let fallbackUsername = user.email?.components(separatedBy: "@").first ?? "user"
                try await client.from("profiles").insert(
                    Profile(
                        id: user.id,
                        username: fallbackUsername,
                        displayName: nil,
                        avatarURL: nil,
                        createdAt: Date()
                    )
                ).execute()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
