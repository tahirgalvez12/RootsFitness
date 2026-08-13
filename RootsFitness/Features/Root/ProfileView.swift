import Supabase
import SwiftUI

private struct ProfileViewModel {
    static func fetchProfile(userID: UUID) async -> Profile? {
        let client = SupabaseClient.shared
        let results: [Profile]? = try? await client
            .from("profiles")
            .select()
            .eq("id", value: userID)
            .execute()
            .value
        return results?.first
    }
}

struct ProfileView: View {
    let currentUserID: UUID
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profile: Profile?
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            RFAvatar(username: profile?.username ?? "?", size: 88)
                            Text(profile?.username ?? "…")
                                .font(.rfLargeTitle)
                                .foregroundStyle(Color.rfTextPrimary)
                        }
                        .padding(.top, 12)

                        RFCard {
                            Button {
                                showSignOutConfirm = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Sign Out")
                                    Spacer()
                                }
                                .font(.rfBody)
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .padding(RFMetrics.screenPadding)
                }
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Sign out?",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task { await authViewModel.signOut() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                profile = await ProfileViewModel.fetchProfile(userID: currentUserID)
            }
        }
    }
}

#Preview {
    ProfileView(currentUserID: UUID())
        .environment(AuthViewModel())
}
