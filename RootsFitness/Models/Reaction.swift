import Foundation

enum ReactionKind: String, Codable, CaseIterable {
    case fire
    case flex
    case clap
    case trophy
    case heart

    var emoji: String {
        switch self {
        case .fire: return "🔥"
        case .flex: return "💪"
        case .clap: return "👏"
        case .trophy: return "🏆"
        case .heart: return "❤️"
        }
    }

    var displayName: String {
        switch self {
        case .fire: return "Fire"
        case .flex: return "Flex"
        case .clap: return "Clap"
        case .trophy: return "Trophy"
        case .heart: return "Heart"
        }
    }
}

struct PostReaction: Codable, Identifiable, Hashable {
    let id: UUID
    let postID: UUID
    let userID: UUID
    var reaction: ReactionKind
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case userID = "user_id"
        case reaction
        case createdAt = "created_at"
    }
}
