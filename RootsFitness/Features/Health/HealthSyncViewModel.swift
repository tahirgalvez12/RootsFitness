import Foundation

@MainActor
@Observable
final class HealthSyncViewModel {
    private(set) var candidates: [HealthWorkoutCandidate] = []
    private(set) var isAuthorized = false

    var errorMessage: String?
    var isSyncing = false
    var isPosting = false

    private let healthKit = HealthKitManager()
    private let postsViewModel: PostsViewModel

    init(postsViewModel: PostsViewModel) {
        self.postsViewModel = postsViewModel
    }

    func sync() async {
        errorMessage = nil
        isSyncing = true
        defer { isSyncing = false }
        do {
            try await healthKit.requestAuthorization()
            isAuthorized = true

            let sinceDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date.distantPast
            let workouts = try await healthKit.fetchRecentWorkouts(since: sinceDate)
            let alreadyImported = await postsViewModel.existingHealthKitUUIDs()

            candidates = workouts
                .map(HealthWorkoutCandidate.init)
                .filter { !alreadyImported.contains($0.id) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleSelection(for id: String) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[index].isSelected.toggle()
    }

    func updateCaption(for id: String, caption: String) {
        guard let index = candidates.firstIndex(where: { $0.id == id }) else { return }
        candidates[index].caption = caption
    }

    /// Posts every selected candidate as an exercise post, then drops it from
    /// the list on success so the sheet reflects what's left to review.
    func postSelected() async {
        errorMessage = nil
        isPosting = true
        defer { isPosting = false }

        let selected = candidates.filter(\.isSelected)
        var postedIDs: Set<String> = []

        for candidate in selected {
            let success = await postsViewModel.createExercisePost(
                caption: candidate.caption.isEmpty ? nil : candidate.caption,
                input: NewExerciseInput(
                    activityType: candidate.activityDisplayName,
                    durationMinutes: candidate.durationMinutes,
                    caloriesBurned: candidate.caloriesBurned,
                    source: .healthkit,
                    healthKitUUID: candidate.id
                ),
                imageData: nil
            )
            if success {
                postedIDs.insert(candidate.id)
            } else {
                errorMessage = postsViewModel.errorMessage
                break
            }
        }

        candidates.removeAll { postedIDs.contains($0.id) }
    }
}
