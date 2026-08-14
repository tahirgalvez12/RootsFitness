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

    /// True once `signUp` has completed and the account requires confirming
    /// via emailed link before a session exists — drives an "check your
    /// email" screen instead of leaving the user stuck on the sign-up form.
    private(set) var awaitingEmailConfirmation = false

    func signUp(email: String, password: String, username: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await client.auth.signUp(email: email, password: password)

            if result.session != nil {
                // Email confirmation is off (or already satisfied) — a
                // session exists immediately, so create the profile now.
                try await client.from("profiles").insert(
                    Profile(
                        id: result.user.id,
                        username: username,
                        displayName: nil,
                        avatarURL: nil,
                        createdAt: Date()
                    )
                ).execute()
            } else {
                // No session yet: confirmation is required. There's no
                // auth.uid() for RLS to check yet, so the profile insert
                // has to wait until the user confirms and actually signs
                // in — remember the chosen username until then so
                // ensureProfileExists can use it instead of an
                // email-derived fallback.
                PendingUsernameStore.save(username, for: result.user.id)
                awaitingEmailConfirmation = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Clears the "check your email" state — call when the user dismisses
    /// that screen or navigates back to try a different email.
    func acknowledgeEmailConfirmationNotice() {
        awaitingEmailConfirmation = false
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
                // Prefer the username chosen at sign-up (stashed by signUp
                // when confirmation was required and no session existed
                // yet to create the profile with); fall back to something
                // derived from the email if that's missing for any reason.
                let fallbackUsername = user.email?.components(separatedBy: "@").first ?? "user"
                let username = PendingUsernameStore.take(for: user.id) ?? fallbackUsername
                try await client.from("profiles").insert(
                    Profile(
                        id: user.id,
                        username: username,
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

/// Bridges the username typed at sign-up to the moment a session first
/// exists for that user, when email confirmation is required and the two
/// happen on different app launches (confirm link opens in Mail/Safari,
/// not necessarily back in this app process). Backed by UserDefaults since
/// it just needs to outlive a process relaunch, not be secure or synced.
private enum PendingUsernameStore {
    private static func key(for userID: UUID) -> String {
        "pendingUsername.\(userID.uuidString)"
    }

    static func save(_ username: String, for userID: UUID) {
        UserDefaults.standard.set(username, forKey: key(for: userID))
    }

    /// Reads and clears in one step — a pending username is only ever
    /// meant to be consumed once, by the first profile creation for that user.
    static func take(for userID: UUID) -> String? {
        let key = key(for: userID)
        let value = UserDefaults.standard.string(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        return value
    }
}
