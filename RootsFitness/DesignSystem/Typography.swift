import SwiftUI

/// Type scale for the "kitchen table, not gym" tone — three families doing
/// three distinct jobs, per the Kin reference design:
///   - Bricolage Grotesque (display/headings): human, slightly irregular —
///     used for names and section titles, the loudest thing on a card.
///   - System sans (body): what people actually write — captions, comments.
///   - DM Mono (data): every number — kcal, kg, macros, timestamps — always
///     small and secondary, never competing with a name or caption.
///
/// Bricolage Grotesque ships from Google Fonts only as a variable font with
/// no static per-weight files, so `BricolageGrotesque-Medium.ttf` and
/// `BricolageGrotesque-Bold.ttf` in RootsFitness/Fonts/ are pre-instantiated
/// static weights (via fonttools varLib.instancer) with corrected name-table
/// records — `Font.custom("Bricolage Grotesque", ...)` would NOT resolve
/// correctly against the original variable font, whose default named
/// instance is "96pt ExtraBold", not a plain family name.
extension Font {
    // Display/headings — Bricolage Grotesque
    static let rfDisplay = Font.custom("Bricolage Grotesque Bold", size: 40)
    static let rfLargeTitle = Font.custom("Bricolage Grotesque Bold", size: 27)
    static let rfTitle = Font.custom("Bricolage Grotesque Medium", size: 22)
    static let rfHeadline = Font.custom("Bricolage Grotesque Medium", size: 14.5)

    // Body — system sans, what people write
    static let rfBody = Font.system(size: 14.5, weight: .regular)
    static let rfSubheadline = Font.system(size: 13, weight: .regular)

    // Data — DM Mono, always small, always secondary
    static let rfCaption = Font.custom("DM Mono", size: 11)
    static let rfData = Font.custom("DM Mono", size: 11.5)
    static let rfLabel = Font.custom("DM Mono", size: 10)

    static let rfButton = Font.custom("Bricolage Grotesque Medium", size: 15)
}
