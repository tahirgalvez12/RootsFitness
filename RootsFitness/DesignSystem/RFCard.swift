import SwiftUI

/// The elevated-surface container used for feed rows, goal cards, and
/// grouped content throughout the app. Separation from the paper background
/// comes primarily from the card/paper tone difference plus a 1px hairline
/// border — the shadow is intentionally subtle, not the heavy "lifted"
/// treatment of the previous design pass.
struct RFCard<Content: View>: View {
    var padding: CGFloat = RFMetrics.cardPadding
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous)
                    .fill(Color.rfSurfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous)
                    .strokeBorder(Color.rfHairline, lineWidth: 1)
            )
            .shadow(
                color: .black.opacity(RFMetrics.cardShadowOpacity),
                radius: RFMetrics.cardShadowRadius,
                x: 0,
                y: 2
            )
    }
}
