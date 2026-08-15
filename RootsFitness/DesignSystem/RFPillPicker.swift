import SwiftUI

/// Custom horizontal pill selector — replaces the stock `.segmented` picker
/// style. Selected pill fills with ink (matching the reference design's
/// `.seg span.on` treatment), unselected pills are hairline-bordered.
struct RFPillPicker<T: Hashable>: View {
    let options: [(value: T, label: String)]
    @Binding var selection: T

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    let isSelected = option.value == selection
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            selection = option.value
                        }
                    } label: {
                        Text(option.label)
                            .font(.rfData)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(isSelected ? Color.rfTextPrimary : Color.clear)
                            )
                            .foregroundStyle(isSelected ? Color.rfSurfaceElevated : Color.rfTextSecondary)
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? .clear : Color.rfHairline,
                                    lineWidth: 1
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
