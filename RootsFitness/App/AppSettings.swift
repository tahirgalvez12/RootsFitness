import Foundation

/// Local, device-only user preferences — units of measurement and
/// notification toggles. Backed by `UserDefaults`, not Supabase: these don't
/// need to follow the user across devices, and adding a `profiles` column
/// for something this lightweight isn't worth a migration yet. Follows the
/// same `@Observable` singleton convention as `SupabaseClient.shared`.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let preferredWeightUnit = "preferredWeightUnit"
        static let notifyFriendRequests = "notifyFriendRequests"
        static let notifyReactionsAndComments = "notifyReactionsAndComments"
    }

    var preferredWeightUnit: WeightUnit {
        didSet {
            UserDefaults.standard.set(preferredWeightUnit.rawValue, forKey: Keys.preferredWeightUnit)
        }
    }

    /// UI-only for now — no APNs/push wiring exists yet. Toggling these
    /// changes what the app *would* notify about once real push
    /// infrastructure lands; it doesn't request notification permission or
    /// send anything today.
    var notifyFriendRequests: Bool {
        didSet {
            UserDefaults.standard.set(notifyFriendRequests, forKey: Keys.notifyFriendRequests)
        }
    }

    var notifyReactionsAndComments: Bool {
        didSet {
            UserDefaults.standard.set(notifyReactionsAndComments, forKey: Keys.notifyReactionsAndComments)
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        if let rawUnit = defaults.string(forKey: Keys.preferredWeightUnit),
           let unit = WeightUnit(rawValue: rawUnit) {
            preferredWeightUnit = unit
        } else {
            preferredWeightUnit = .lb
        }

        notifyFriendRequests = defaults.object(forKey: Keys.notifyFriendRequests) as? Bool ?? true
        notifyReactionsAndComments = defaults.object(forKey: Keys.notifyReactionsAndComments) as? Bool ?? true
    }

    /// Converts a stored weight value to the user's preferred display unit.
    /// Storage is untouched — `PostWeight` keeps whichever unit was chosen
    /// at post time; this only affects how `FeedView` renders it.
    func displayWeight(_ value: Double, storedUnit: WeightUnit) -> (value: Double, unit: WeightUnit) {
        guard storedUnit != preferredWeightUnit else {
            return (value, storedUnit)
        }
        switch (storedUnit, preferredWeightUnit) {
        case (.lb, .kg):
            return (value * 0.45359237, .kg)
        case (.kg, .lb):
            return (value / 0.45359237, .lb)
        default:
            return (value, storedUnit)
        }
    }
}
