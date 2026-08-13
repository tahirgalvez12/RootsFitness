import Foundation
import HealthKit

/// A HealthKit workout not yet imported as a post, plus UI review state.
/// Wraps the fields the app cares about so the view layer doesn't need to
/// import HealthKit directly.
struct HealthWorkoutCandidate: Identifiable {
    let id: String
    let activityDisplayName: String
    let startDate: Date
    let durationMinutes: Int
    let caloriesBurned: Int?

    var isSelected: Bool = true
    var caption: String = ""

    init(workout: HKWorkout) {
        self.id = workout.uuid.uuidString.lowercased()
        self.activityDisplayName = HealthWorkoutCandidate.displayName(for: workout.workoutActivityType)
        self.startDate = workout.startDate
        self.durationMinutes = Int(workout.duration / 60)
        if let energy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?
            .sumQuantity()?.doubleValue(for: .kilocalorie()) {
            self.caloriesBurned = Int(energy)
        } else {
            self.caloriesBurned = nil
        }
    }

    private static func displayName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength Training"
        case .hiking: return "Hiking"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .coreTraining: return "Core Training"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Workout"
        }
    }
}
