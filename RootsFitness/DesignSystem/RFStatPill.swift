import SwiftUI

/// Small rounded stat chip — used for duration/calories/macro readouts in
/// feed cards, replacing plain `Label`/`Text` rows.
struct RFStatPill: View {
    let icon: String
    let text: String
    var tint: Color = .rfAccent

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text(text)
                .font(.rfCaption)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(tint.opacity(0.12))
        )
    }
}
