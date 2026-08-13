import SwiftUI

/// Subtle accent-tinted gradient background used behind auth screens —
/// replaces the flat system background with something that carries the
/// brand color without overwhelming the content on top of it.
struct RFBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.rfAccent.opacity(0.14),
                Color.rfSurfacePrimary,
                Color.rfSurfacePrimary,
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
