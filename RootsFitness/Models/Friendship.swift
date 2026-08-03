import Foundation

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
}

struct Friendship: Codable, Hashable {
    let userID: UUID
    let friendID: UUID
    var status: FriendshipStatus
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case friendID = "friend_id"
        case status
        case createdAt = "created_at"
    }
}
