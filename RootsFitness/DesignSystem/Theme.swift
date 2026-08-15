import SwiftUI

/// Semantic color tokens for the RootsFitness design system — "kitchen
/// table, not gym": sage paper, deep forest ink, dried rose, wheat. Every
/// value is backed by a named color in Assets.xcassets with Any/Dark
/// appearance variants, so light/dark mode adapt automatically — never
/// hardcode hex values in view code, reference these tokens instead.
extension Color {
    /// Primary brand color — dried rose. Reserved for small highlights (the
    /// "now" marker in a week ribbon, active toggle states) rather than
    /// large filled surfaces — buttons use ink, not accent, per the
    /// reference design's restraint. Also drives system tint via
    /// AccentColor.colorset.
    static let rfAccent = Color("AccentBrand")

    /// Secondary accent — wheat. Used sparingly alongside rose for warmth
    /// without competing with it.
    static let rfAccentSecondary = Color("AccentBrandSecondary")

    /// Screen background — sage paper (dark: warm forest-tinted near-black,
    /// not neutral gray), distinct from the card surface so elevated
    /// content has visible lift without needing a heavy shadow.
    static let rfSurfacePrimary = Color("SurfacePrimary")

    /// Card/elevated-content background.
    static let rfSurfaceElevated = Color("SurfaceElevated")

    static let rfTextPrimary = Color("TextPrimary")
    static let rfTextSecondary = Color("TextSecondary")

    /// Hairline border/divider color — the reference design uses 1px
    /// low-opacity hairlines instead of shadows to separate content
    /// (card borders, dividers, unfilled week-ribbon marks, outlined pills).
    static let rfHairline = Color("Hairline")
}

/// Shared layout constants so spacing/radius stay consistent across every
/// screen instead of each view picking its own numbers.
enum RFMetrics {
    static let cardCornerRadius: CGFloat = 14
    static let controlCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20

    /// Much subtler than the previous "bold/energetic" pass — the reference
    /// design relies on the paper/card tone difference plus a 1px hairline
    /// border to separate content, not a heavy drop shadow.
    static let cardShadowRadius: CGFloat = 6
    static let cardShadowOpacity: Double = 0.04

    /// Cap on a feed post's full-bleed hero image height. A true 1:1 square
    /// at full device width leaves the reaction/comment row below the fold
    /// with no visual cue more content follows — this keeps the photo large
    /// and prominent while leaving the actions row visible without
    /// scrolling on most posts.
    static let heroMediaMaxHeight: CGFloat = 280
}
