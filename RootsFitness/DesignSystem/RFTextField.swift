import SwiftUI

/// Quiet, editorial input treatment — a bottom hairline rather than boxed
/// fill+border chrome, matching the reference design's restraint (its forms
/// have no visible field "container" at all, just a rule under each input).
struct RFTextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: Bool = true

    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.bottom, 10)

            Rectangle()
                .fill(Color.rfHairline)
                .frame(height: 1)
        }
    }
}
