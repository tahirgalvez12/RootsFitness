import SwiftUI

/// Full-width, ink-filled primary action button — the main call-to-action
/// treatment used for Log In, Sign Up, Post, Save, Add Friend, etc. Filled
/// with ink (text-primary color) rather than the accent color: rose is
/// reserved for small highlights, not large filled surfaces, per the
/// reference design's restraint principle.
struct RFPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(Color.rfSurfaceElevated)
                } else {
                    Text(title)
                        .font(.rfButton)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                .fill(isDisabled ? Color.rfTextPrimary.opacity(0.35) : Color.rfTextPrimary)
        )
        .foregroundStyle(Color.rfSurfaceElevated)
        .disabled(isDisabled || isLoading)
    }
}

/// Secondary/outline action button — used for less prominent actions
/// alongside a primary button (e.g. "Cancel", "Decline").
struct RFSecondaryButton: View {
    let title: String
    var role: ButtonRole? = nil
    let action: () -> Void

    private var tint: Color {
        role == .destructive ? .red : .rfTextPrimary
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rfButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                .strokeBorder(role == .destructive ? tint.opacity(0.5) : Color.rfHairline, lineWidth: 1)
        )
        .foregroundStyle(tint)
    }
}
