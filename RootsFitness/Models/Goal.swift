import Foundation

enum GoalType: String, Codable, CaseIterable {
    case loseWeight = "lose_weight"
    case bulk
    case generalFitness = "general_fitness"

    var displayName: String {
        switch self {
        case .loseWeight: return "Lose Weight"
        case .bulk: return "Bulk"
        case .generalFitness: return "General Fitness"
        }
    }
}

struct Goal: Codable, Identifiable, Hashable {
    let id: UUID
    let userID: UUID
    var type: GoalType
    var targetValue: Double?
    var targetDate: Date?
    var isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case type
        case targetValue = "target_value"
        case targetDate = "target_date"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
