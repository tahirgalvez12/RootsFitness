import SwiftUI

/// Full-width, bold, rounded primary action button — the main call-to-action
/// treatment used for Log In, Sign Up, Post, Save, Add Friend, etc.
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
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.rfButton)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                .fill(isDisabled ? Color.rfAccent.opacity(0.4) : Color.rfAccent)
        )
        .foregroundStyle(.white)
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
        role == .destructive ? .red : .rfAccent
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.rfButton)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                .strokeBorder(tint, lineWidth: 1.5)
        )
        .foregroundStyle(tint)
    }
}
