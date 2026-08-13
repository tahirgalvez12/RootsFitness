import SwiftUI

/// Empty-state treatment — icon in a hairline-bordered rounded square rather
/// than a large filled color block, matching the reference design's overall
/// restraint (nothing in it uses a solid color fill for an icon badge).
struct RFEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.rfSurfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.rfHairline, lineWidth: 1)
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(Color.rfTextSecondary)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.rfTitle)
                    .foregroundStyle(Color.rfTextPrimary)
                Text(message)
                    .font(.rfBody)
                    .foregroundStyle(Color.rfTextSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                RFPrimaryButton(title: actionTitle, action: action)
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
