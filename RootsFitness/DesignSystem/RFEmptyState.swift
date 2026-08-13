import SwiftUI

/// Styled empty-state treatment — icon rendered in an accent-tinted circle
/// rather than plain gray, matching the bolder athletic tone. Used for Feed,
/// Goals, and HealthKit sync empty states.
struct RFEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.rfAccent.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: icon)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Color.rfAccent)
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
