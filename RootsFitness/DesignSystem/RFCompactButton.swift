import SwiftUI

/// Small pill-shaped action button for inline row actions (Accept/Decline,
/// Add) where a full-width RFPrimaryButton wouldn't fit — e.g. a friend
/// request row. Filled variant uses ink (not accent), matching the primary
/// button treatment; destructive stays red for clarity.
struct RFCompactButton: View {
    let title: String
    var isFilled: Bool = true
    var role: ButtonRole? = nil
    let action: () -> Void

    private var tint: Color {
        role == .destructive ? .red : .rfTextPrimary
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rfData)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
        }
        .background(
            Capsule().fill(isFilled ? tint : Color.clear)
        )
        .overlay(
            Capsule().strokeBorder(isFilled ? .clear : tint.opacity(role == .destructive ? 0.5 : 1), lineWidth: 1)
        )
        .foregroundStyle(isFilled ? Color.rfSurfaceElevated : tint)
    }
}
