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

    // `target_date` is a Postgres `date` column (no time component), which
    // doesn't match the SDK's default `yyyy-MM-dd'T'HH:mm:ss` Date decoding
    // strategy — decode/encode it manually as a plain calendar date.
    static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    init(
        id: UUID,
        userID: UUID,
        type: GoalType,
        targetValue: Double?,
        targetDate: Date?,
        isActive: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.type = type
        self.targetValue = targetValue
        self.targetDate = targetDate
        self.isActive = isActive
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userID = try container.decode(UUID.self, forKey: .userID)
        type = try container.decode(GoalType.self, forKey: .type)
        targetValue = try container.decodeIfPresent(Double.self, forKey: .targetValue)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        if let dateString = try container.decodeIfPresent(String.self, forKey: .targetDate) {
            targetDate = Goal.dateOnlyFormatter.date(from: dateString)
        } else {
            targetDate = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userID, forKey: .userID)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(targetValue, forKey: .targetValue)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        if let targetDate {
            try container.encode(Goal.dateOnlyFormatter.string(from: targetDate), forKey: .targetDate)
        }
    }
}
