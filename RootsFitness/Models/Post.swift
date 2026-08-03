import Foundation

enum PostType: String, Codable, CaseIterable {
    case exercise
    case weight
    case meal
    case progressPic = "progress_pic"
}

struct Post: Codable, Identifiable, Hashable {
    let id: UUID
    let userID: UUID
    var type: PostType
    var caption: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case type
        case caption
        case createdAt = "created_at"
    }
}

enum ExerciseSource: String, Codable {
    case manual
    case healthkit
}

struct PostExercise: Codable, Hashable {
    let postID: UUID
    var activityType: String
    var durationMinutes: Int?
    var caloriesBurned: Int?
    var source: ExerciseSource
    var healthKitUUID: String?

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case activityType = "activity_type"
        case durationMinutes = "duration_minutes"
        case caloriesBurned = "calories_burned"
        case source
        case healthKitUUID = "healthkit_uuid"
    }
}

enum WeightUnit: String, Codable {
    case lb
    case kg
}

struct PostWeight: Codable, Hashable {
    let postID: UUID
    var weightValue: Double
    var unit: WeightUnit

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case weightValue = "weight_value"
        case unit
    }
}

struct PostMeal: Codable, Hashable {
    let postID: UUID
    var mealName: String?
    var calories: Int?
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case mealName = "meal_name"
        case calories
        case proteinGrams = "protein_g"
        case carbsGrams = "carbs_g"
        case fatGrams = "fat_g"
    }
}

struct PostMedia: Codable, Identifiable, Hashable {
    let id: UUID
    let postID: UUID
    var storagePath: String
    var position: Int

    enum CodingKeys: String, CodingKey {
        case id
        case postID = "post_id"
        case storagePath = "storage_path"
        case position
    }
}
