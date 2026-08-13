import SwiftUI

/// Small rounded stat chip — used for duration/calories/macro readouts in
/// feed cards, replacing plain `Label`/`Text` rows. Solid-fill treatment
/// (white text/icon on the saturated tint) rather than a translucent tint
/// wash, so stats read as confident data points, not decoration.
struct RFStatPill: View {
    let icon: String
    let text: String
    var tint: Color = .rfAccent

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.rfCaption)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(tint)
        )
    }
}
