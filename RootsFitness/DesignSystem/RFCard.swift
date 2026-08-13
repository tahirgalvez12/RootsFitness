import SwiftUI

/// The elevated-surface container used for feed rows, goal cards, and
/// grouped content throughout the app — rounded corners, subtle shadow,
/// `rfSurfaceElevated` background so cards read as "lifted" off the screen.
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
            .shadow(
                color: .black.opacity(RFMetrics.cardShadowOpacity),
                radius: RFMetrics.cardShadowRadius,
                x: 0,
                y: 4
            )
    }
}
