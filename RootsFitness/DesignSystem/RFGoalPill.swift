import SwiftUI

/// Small outlined capsule showing a goal type — mono label, hairline
/// border, no fill. Replaces any colored goal badge; matches the reference
/// design's quiet `.goal` treatment (a goal is context, not a score).
struct RFGoalPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.rfLabel)
            .foregroundStyle(Color.rfTextSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .overlay(
                Capsule().strokeBorder(Color.rfHairline, lineWidth: 1)
            )
    }
}
