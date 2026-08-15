import SwiftUI

/// Flat screen background — the reference design has no gradient wash
/// anywhere; kept as a component (rather than inlining `Color.rfSurfacePrimary`
/// at each call site) so auth screens don't need individual edits if the
/// background treatment changes again later.
struct RFBackground: View {
    var body: some View {
        Color.rfSurfacePrimary
            .ignoresSafeArea()
    }
}
