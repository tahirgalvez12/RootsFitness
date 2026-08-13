import Foundation
import Supabase

@MainActor
@Observable
final class GoalsViewModel {
    private(set) var currentGoal: Goal?
    private(set) var history: [Goal] = []

    var errorMessage: String?
    var isLoading = false
    var isSaving = false

    private let client = SupabaseClient.shared
    private let currentUserID: UUID

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
    }

    func refresh() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            async let currentTask: [Goal] = client
                .from("goals")
                .select()
                .eq("user_id", value: currentUserID)
                .eq("is_active", value: true)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            async let historyTask: [Goal] = client
                .from("goals")
                .select()
                .eq("user_id", value: currentUserID)
                .eq("is_active", value: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            let (current, past) = try await (currentTask, historyTask)
            currentGoal = current.first
            history = past
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setGoal(type: GoalType, targetValue: Double?, targetDate: Date?) async -> Bool {
        errorMessage = nil
        isSaving = true
        defer { isSaving = false }
        do {
            if let currentGoal {
                try await client
                    .from("goals")
                    .update(GoalActiveUpdate(isActive: false))
                    .eq("id", value: currentGoal.id)
                    .execute()
            }

            try await client.from("goals").insert(
                NewGoalRow(
                    userID: currentUserID,
                    type: type,
                    targetValue: targetValue,
                    targetDate: targetDate
                )
            ).execute()

            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func endGoal() async {
        guard let currentGoal else { return }
        errorMessage = nil
        do {
            try await client
                .from("goals")
                .update(GoalActiveUpdate(isActive: false))
                .eq("id", value: currentGoal.id)
                .execute()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct GoalActiveUpdate: Encodable {
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
    }
}

private struct NewGoalRow: Encodable {
    let userID: UUID
    let type: GoalType
    let targetValue: Double?
    let targetDate: Date?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case type
        case targetValue = "target_value"
        case targetDate = "target_date"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userID, forKey: .userID)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(targetValue, forKey: .targetValue)
        if let targetDate {
            try container.encode(Goal.dateOnlyFormatter.string(from: targetDate), forKey: .targetDate)
        }
    }
}
