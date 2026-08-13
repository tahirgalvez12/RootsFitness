import SwiftUI

/// Custom horizontal pill selector — replaces the stock `.segmented` picker
/// style with a bolder, rounded-capsule treatment matching the athletic tone.
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
                            .font(.rfSubheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(isSelected ? Color.rfAccent : Color.rfSurfaceElevated)
                            )
                            .foregroundStyle(isSelected ? .white : Color.rfTextPrimary)
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? .clear : Color.rfTextSecondary.opacity(0.15),
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
