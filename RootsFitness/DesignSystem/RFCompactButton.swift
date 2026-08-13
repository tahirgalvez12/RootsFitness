import SwiftUI

/// Small pill-shaped action button for inline row actions (Accept/Decline,
/// Add) where a full-width RFPrimaryButton wouldn't fit — e.g. a friend
/// request row.
struct RFCompactButton: View {
    let title: String
    var isFilled: Bool = true
    var role: ButtonRole? = nil
    let action: () -> Void

    private var tint: Color {
        role == .destructive ? .red : .rfAccent
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rfCaption)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .background(
            Capsule().fill(isFilled ? tint : Color.clear)
        )
        .overlay(
            Capsule().strokeBorder(tint, lineWidth: isFilled ? 0 : 1.5)
        )
        .foregroundStyle(isFilled ? .white : tint)
    }
}
