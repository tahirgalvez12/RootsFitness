import Foundation
import HealthKit

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data isn't available on this device."
        case .authorizationDenied:
            return "RootsFitness doesn't have permission to read your workouts. Enable access in Settings > Privacy > Health."
        }
    }
}

/// Thin wrapper around HKHealthStore — keeps the `HealthKit` import contained
/// to this one file, mirroring how `Storage`/`Supabase` are scoped elsewhere.
struct HealthKitManager {
    private let store = HKHealthStore()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        let workoutType = HKObjectType.workoutType()
        try await store.requestAuthorization(toShare: [], read: [workoutType])
    }

    #if DEBUG
    /// Debug-only: seeds a synthetic workout into the Simulator's Health store
    /// so the sync flow can be verified without a real device/Watch. Requests
    /// write authorization only when called — production read flow never
    /// requests `toShare`.
    func seedDebugWorkout() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        let workoutType = HKObjectType.workoutType()
        try await store.requestAuthorization(toShare: [workoutType], read: [workoutType])

        let start = Date().addingTimeInterval(-3600)
        let end = Date().addingTimeInterval(-1800)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: 250)
        let workout = HKWorkout(
            activityType: .running,
            start: start,
            end: end,
            workoutEvents: nil,
            totalEnergyBurned: energyQuantity,
            totalDistance: nil,
            metadata: nil
        )
        try await store.save(workout)
    }
    #endif

    /// Fetches workouts more recent than `since`, newest first.
    func fetchRecentWorkouts(since: Date) async throws -> [HKWorkout] {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: since, end: nil)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: 50,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            store.execute(query)
        }
    }
}
