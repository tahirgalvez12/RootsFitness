import SwiftUI

/// Groups raw reaction rows by kind and renders a tappable emoji-pill row —
/// each pill shows the emoji + count, highlighted when the current user has
/// reacted with that kind. Reused in the feed card (summary) and post
/// detail (full picker).
struct RFReactionBar: View {
    let reactions: [PostReaction]
    let currentUserID: UUID
    /// When true, shows a pill for every ReactionKind (even zero-count) so
    /// the user can tap to add a new reaction — used in the detail picker.
    var showAllKinds: Bool = false
    let onToggle: (ReactionKind) -> Void

    private var countsByKind: [ReactionKind: Int] {
        Dictionary(grouping: reactions, by: \.reaction).mapValues(\.count)
    }

    private var kindsToShow: [ReactionKind] {
        if showAllKinds {
            return ReactionKind.allCases
        }
        return ReactionKind.allCases.filter { (countsByKind[$0] ?? 0) > 0 }
    }

    private func hasReacted(_ kind: ReactionKind) -> Bool {
        reactions.contains { $0.userID == currentUserID && $0.reaction == kind }
    }

    var body: some View {
        if kindsToShow.isEmpty && !showAllKinds {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(kindsToShow, id: \.self) { kind in
                        pill(for: kind)
                    }
                }
            }
        }
    }

    private func pill(for kind: ReactionKind) -> some View {
        let count = countsByKind[kind] ?? 0
        let isActive = hasReacted(kind)
        return Button {
            onToggle(kind)
        } label: {
            HStack(spacing: 4) {
                Text(kind.emoji)
                if count > 0 {
                    Text("\(count)")
                        .font(.rfCaption)
                        .foregroundStyle(isActive ? .white : Color.rfTextPrimary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(isActive ? Color.rfAccent : Color.rfSurfacePrimary)
            )
            .overlay(
                Capsule().strokeBorder(isActive ? .clear : Color.rfTextSecondary.opacity(0.15), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}
