import SwiftUI

/// Semantic color tokens for the RootsFitness design system. Every value is
/// backed by a named color in Assets.xcassets with Any/Dark appearance
/// variants, so light/dark mode adapt automatically — never hardcode hex
/// values in view code, reference these tokens instead.
extension Color {
    /// Primary brand color — vibrant blue-violet. Also drives system tint
    /// (nav bars, default button/control colors) via AccentColor.colorset.
    static let rfAccent = Color("AccentBrand")

    /// Secondary accent — warm coral, used sparingly for highlights,
    /// celebratory moments (goal hit), and the progress-pic post type.
    static let rfAccentSecondary = Color("AccentBrandSecondary")

    /// Screen background — a very subtle off-white/off-black, distinct from
    /// pure white/black so elevated cards have visible lift.
    static let rfSurfacePrimary = Color("SurfacePrimary")

    /// Card/elevated-content background.
    static let rfSurfaceElevated = Color("SurfaceElevated")

    static let rfTextPrimary = Color("TextPrimary")
    static let rfTextSecondary = Color("TextSecondary")

    /// Per-post-type tints, used for icon badges so activity types are
    /// distinguishable at a glance in the feed.
    static func rfPostType(_ type: PostType) -> Color {
        switch type {
        case .exercise: return Color("PostExercise")
        case .weight: return Color("PostWeight")
        case .meal: return Color("PostMeal")
        case .progressPic: return Color("PostProgressPic")
        }
    }
}

/// Shared layout constants so spacing/radius stay consistent across every
/// restyled screen instead of each view picking its own numbers.
enum RFMetrics {
    static let cardCornerRadius: CGFloat = 20
    static let controlCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
    static let cardShadowRadius: CGFloat = 12
    static let cardShadowOpacity: Double = 0.08

    /// Cap on a feed post's full-bleed hero image height. A true 1:1 square
    /// at full device width leaves the reaction/comment row below the fold
    /// with no visual cue more content follows — this keeps the photo large
    /// and prominent while leaving the actions row visible without
    /// scrolling on most posts.
    static let heroMediaMaxHeight: CGFloat = 340
}
