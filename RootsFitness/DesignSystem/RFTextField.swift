import SwiftUI

/// Consistent rounded input field treatment — replaces the ad-hoc
/// `.padding().background(.quaternary, in: RoundedRectangle(...))` pattern
/// that was copy-pasted across every form in the app.
struct RFTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: Bool = true

    var body: some View {
        Group {
            if isSecure {
                SecureField(title, text: $text)
            } else {
                TextField(title, text: $text)
                    .textInputAutocapitalization(autocapitalization ? .sentences : .never)
                    .autocorrectionDisabled(!autocapitalization)
            }
        }
        .keyboardType(keyboardType)
        .textContentType(textContentType)
        .font(.rfBody)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                .fill(Color.rfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RFMetrics.controlCornerRadius, style: .continuous)
                .strokeBorder(Color.rfTextSecondary.opacity(0.15), lineWidth: 1)
        )
    }
}
