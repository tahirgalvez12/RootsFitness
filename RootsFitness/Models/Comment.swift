import Foundation

struct PostComment: Codable, Identifiable, Hashable {
    let id: UUID
    let postID: UUID
    let userID: UUID
    var body: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case userID = "user_id"
        case body
        case createdAt = "created_at"
    }
}
