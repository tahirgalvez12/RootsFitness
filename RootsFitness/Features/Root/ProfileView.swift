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

    /// Post creation dates for the current user going back `weeks` weeks —
    /// used to derive the "Showing up" week grid. No new table: this is
    /// computed client-side from the same `posts` rows already visible
    /// under existing self-row RLS.
    static func fetchRecentPostDates(userID: UUID, weeks: Int) async -> [Date] {
        let client = SupabaseClient.shared
        let since = Calendar.current.date(byAdding: .day, value: -(weeks * 7), to: Date()) ?? Date()
        struct CreatedAtRow: Decodable {
            let createdAt: Date
            enum CodingKeys: String, CodingKey { case createdAt = "created_at" }
        }
        let rows: [CreatedAtRow]? = try? await client
            .from("posts")
            .select("created_at")
            .eq("user_id", value: userID)
            .gte("created_at", value: since.ISO8601Format())
            .execute()
            .value
        return rows?.map(\.createdAt) ?? []
    }
}

/// Builds a 5-week grid of Bool (oldest week first, newest last, each week
/// Sunday→Saturday-ish per `Calendar.current`'s first weekday) from a flat
/// list of post dates — any post on a given calendar day marks that day
/// "on" in the ribbon.
private func weekGrid(from postDates: [Date], weeks: Int) -> [[Bool]] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let activeDays = Set(postDates.map { calendar.startOfDay(for: $0) })

    // Oldest day first: weeks * 7 days ago through today.
    let totalDays = weeks * 7
    var days: [Bool] = []
    for offset in stride(from: totalDays - 1, through: 0, by: -1) {
        guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
        days.append(activeDays.contains(day))
    }
    return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<min($0 + 7, days.count)]) }
}

struct ProfileView: View {
    let currentUserID: UUID
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var profile: Profile?
    @State private var goalsViewModel: GoalsViewModel?
    @State private var recentPostDates: [Date] = []
    @State private var showSignOutConfirm = false

    private var weeks: [[Bool]] {
        weekGrid(from: recentPostDates, weeks: 5)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        showingUpSection

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
            .navigationTitle("You")
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
                recentPostDates = await ProfileViewModel.fetchRecentPostDates(userID: currentUserID, weeks: 5)
                let viewModel = GoalsViewModel(currentUserID: currentUserID)
                await viewModel.refresh()
                goalsViewModel = viewModel
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            RFAvatar(username: profile?.username ?? "?", size: 64)
            Text(profile?.username ?? "…")
                .font(.rfLargeTitle)
                .foregroundStyle(Color.rfTextPrimary)

            if let goal = goalsViewModel?.currentGoal {
                HStack(spacing: 8) {
                    RFGoalPill(label: goal.type.displayName.uppercased())
                    Text("since \(goal.createdAt.formatted(.dateTime.month(.abbreviated).day()))")
                        .font(.rfData)
                        .foregroundStyle(Color.rfTextSecondary)
                }
            }
        }
    }

    private var showingUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SHOWING UP")
                .font(.rfLabel)
                .foregroundStyle(Color.rfTextSecondary)

            RFWeekGrid(weeks: weeks)

            let activeCount = recentPostDates.count
            Text(activeCount > 0
                 ? "\(activeCount) posts these last 5 weeks. Gaps included — they're part of it."
                 : "Nothing yet these last 5 weeks. Post something to start showing up here.")
                .font(.rfSubheadline)
                .foregroundStyle(Color.rfTextSecondary)
        }
    }
}

#Preview {
    ProfileView(currentUserID: UUID())
        .environment(AuthViewModel())
}
