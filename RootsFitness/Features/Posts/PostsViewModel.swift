import Foundation
import Storage
import Supabase

struct NewExerciseInput {
    var activityType: String
    var durationMinutes: Int?
    var caloriesBurned: Int?
    var source: ExerciseSource = .manual
    var healthKitUUID: String? = nil
}

struct NewWeightInput {
    var weightValue: Double
    var unit: WeightUnit
}

struct NewMealInput {
    var mealName: String?
    var calories: Int?
    var proteinGrams: Double?
    var carbsGrams: Double?
    var fatGrams: Double?
}

@MainActor
@Observable
final class PostsViewModel {
    private(set) var feedItems: [FeedItem] = []
    private(set) var signedURLs: [UUID: URL] = [:]

    var errorMessage: String?
    var isLoading = false
    var isPosting = false

    private let client = SupabaseClient.shared
    private let currentUserID: UUID
    private let bucket = "post-media"

    init(currentUserID: UUID) {
        self.currentUserID = currentUserID
    }

    func refresh() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let posts: [Post] = try await client
                .from("posts")
                .select()
                .order("created_at", ascending: false)
                .limit(100)
                .execute()
                .value

            let exercisePostIDs = posts.filter { $0.type == .exercise }.map(\.id)
            let weightPostIDs = posts.filter { $0.type == .weight }.map(\.id)
            let mealPostIDs = posts.filter { $0.type == .meal }.map(\.id)
            let allPostIDs = posts.map(\.id)

            async let exercisesTask: [PostExercise] = exercisePostIDs.isEmpty ? [] : client
                .from("post_exercise").select().in("post_id", values: exercisePostIDs)
                .execute().value

            async let weightsTask: [PostWeight] = weightPostIDs.isEmpty ? [] : client
                .from("post_weight").select().in("post_id", values: weightPostIDs)
                .execute().value

            async let mealsTask: [PostMeal] = mealPostIDs.isEmpty ? [] : client
                .from("post_meal").select().in("post_id", values: mealPostIDs)
                .execute().value

            async let mediaTask: [PostMedia] = allPostIDs.isEmpty ? [] : client
                .from("post_media").select().in("post_id", values: allPostIDs).order("position")
                .execute().value

            let (exercises, weights, meals, media) = try await (exercisesTask, weightsTask, mealsTask, mediaTask)

            let exerciseByPost = Dictionary(uniqueKeysWithValues: exercises.map { ($0.postID, $0) })
            let weightByPost = Dictionary(uniqueKeysWithValues: weights.map { ($0.postID, $0) })
            let mealByPost = Dictionary(uniqueKeysWithValues: meals.map { ($0.postID, $0) })
            let mediaByPost = Dictionary(grouping: media, by: \.postID)

            feedItems = posts.compactMap { post -> FeedItem? in
                let postMedia = mediaByPost[post.id] ?? []
                switch post.type {
                case .exercise:
                    guard let exercise = exerciseByPost[post.id] else { return nil }
                    return .exercise(post, exercise, postMedia)
                case .weight:
                    guard let weight = weightByPost[post.id] else { return nil }
                    return .weight(post, weight, postMedia)
                case .meal:
                    guard let meal = mealByPost[post.id] else { return nil }
                    return .meal(post, meal, postMedia)
                case .progressPic:
                    return .progressPic(post, postMedia)
                }
            }

            await resolveSignedURLs(for: media)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveSignedURLs(for media: [PostMedia]) async {
        await withTaskGroup(of: (UUID, URL?).self) { group in
            for item in media where signedURLs[item.id] == nil {
                group.addTask { [client, bucket] in
                    let url = try? await client.storage.from(bucket)
                        .createSignedURL(path: item.storagePath, expiresIn: 3600)
                    return (item.id, url)
                }
            }
            for await (mediaID, url) in group {
                if let url {
                    signedURLs[mediaID] = url
                }
            }
        }
    }

    func createExercisePost(caption: String?, input: NewExerciseInput, imageData: Data?) async -> Bool {
        await createPost(type: .exercise, caption: caption, imageData: imageData) { postID in
            try await self.client.from("post_exercise").insert(
                PostExercise(
                    postID: postID,
                    activityType: input.activityType,
                    durationMinutes: input.durationMinutes,
                    caloriesBurned: input.caloriesBurned,
                    source: input.source,
                    healthKitUUID: input.healthKitUUID
                )
            ).execute()
        }
    }

    /// HealthKit workout UUIDs already imported as posts by the current user, for
    /// HealthSyncViewModel to filter out before showing sync candidates.
    func existingHealthKitUUIDs() async -> Set<String> {
        do {
            let ownExercisePosts: [PostIDRow] = try await client
                .from("posts")
                .select("id")
                .eq("user_id", value: currentUserID)
                .eq("type", value: PostType.exercise.rawValue)
                .execute()
                .value
            let postIDs = ownExercisePosts.map(\.id)
            guard !postIDs.isEmpty else { return [] }

            let rows: [PostExercise] = try await client
                .from("post_exercise")
                .select()
                .in("post_id", values: postIDs)
                .execute()
                .value
            return Set(rows.compactMap(\.healthKitUUID))
        } catch {
            return []
        }
    }

    func createWeightPost(caption: String?, input: NewWeightInput, imageData: Data?) async -> Bool {
        await createPost(type: .weight, caption: caption, imageData: imageData) { postID in
            try await self.client.from("post_weight").insert(
                PostWeight(postID: postID, weightValue: input.weightValue, unit: input.unit)
            ).execute()
        }
    }

    func createMealPost(caption: String?, input: NewMealInput, imageData: Data?) async -> Bool {
        await createPost(type: .meal, caption: caption, imageData: imageData) { postID in
            try await self.client.from("post_meal").insert(
                PostMeal(
                    postID: postID,
                    mealName: input.mealName,
                    calories: input.calories,
                    proteinGrams: input.proteinGrams,
                    carbsGrams: input.carbsGrams,
                    fatGrams: input.fatGrams
                )
            ).execute()
        }
    }

    func createProgressPicPost(caption: String?, imageData: Data) async -> Bool {
        await createPost(type: .progressPic, caption: caption, imageData: imageData, childInsert: nil)
    }

    private func createPost(
        type: PostType,
        caption: String?,
        imageData: Data?,
        childInsert: ((UUID) async throws -> Void)?
    ) async -> Bool {
        errorMessage = nil
        isPosting = true
        defer { isPosting = false }
        do {
            let post: Post = try await client
                .from("posts")
                .insert(NewPostRow(userID: currentUserID, type: type, caption: caption))
                .select()
                .single()
                .execute()
                .value

            if let childInsert {
                try await childInsert(post.id)
            }

            if let imageData {
                let path = "\(currentUserID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
                try await client.storage.from(bucket).upload(
                    path,
                    data: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )
                try await client.from("post_media").insert(
                    NewPostMediaRow(postID: post.id, storagePath: path, position: 0)
                ).execute()
            }

            await refresh()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private struct NewPostRow: Encodable {
    let userID: UUID
    let type: PostType
    let caption: String?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case type
        case caption
    }
}

private struct PostIDRow: Decodable {
    let id: UUID
}

private struct NewPostMediaRow: Encodable {
    let postID: UUID
    let storagePath: String
    let position: Int

    enum CodingKeys: String, CodingKey {
        case postID = "post_id"
        case storagePath = "storage_path"
        case position
    }
}
