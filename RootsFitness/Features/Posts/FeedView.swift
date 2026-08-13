import SwiftUI

struct FeedView: View {
    @State var viewModel: PostsViewModel
    @State private var showNewPost = false
    @State private var showHealthSync = false
    @State private var selectedItem: FeedItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                if viewModel.feedItems.isEmpty && !viewModel.isLoading {
                    RFEmptyState(
                        icon: "figure.run",
                        title: "No Posts Yet",
                        message: "Friends' workouts, meals, and progress will show up here.",
                        actionTitle: "Create a Post"
                    ) {
                        showNewPost = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.feedItems) { item in
                                FeedItemCard(
                                    item: item,
                                    signedURLs: viewModel.signedURLs,
                                    posterUsername: viewModel.usernamesByUserID[item.post.userID],
                                    reactions: viewModel.reactionsByPost[item.post.id] ?? [],
                                    commentCount: viewModel.commentCountByPost[item.post.id] ?? 0,
                                    currentUserID: viewModel.currentUserID,
                                    onToggleReaction: { kind in
                                        Task { await viewModel.toggleReaction(postID: item.post.id, kind: kind) }
                                    },
                                    onOpenDetail: { selectedItem = item }
                                )
                            }
                        }
                        .padding(.horizontal, RFMetrics.screenPadding)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showHealthSync = true
                    } label: {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(Color.rfAccent)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewPost = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.rfAccent)
                    }
                }
            }
            .sheet(isPresented: $showNewPost) {
                NewPostView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHealthSync) {
                HealthSyncView(viewModel: HealthSyncViewModel(postsViewModel: viewModel))
            }
            .sheet(item: $selectedItem) { item in
                PostDetailView(
                    item: item,
                    signedURLs: viewModel.signedURLs,
                    currentUserID: viewModel.currentUserID,
                    initialReactions: viewModel.reactionsByPost[item.post.id] ?? []
                )
            }
            .task {
                await viewModel.refresh()
            }
        }
    }
}

/// Shared post-summary rendering (header/stats/caption/media) — used by both
/// the feed card and the post detail screen so the layout isn't duplicated.
/// Not itself a `View`: callers compose `textContent` (padded
/// header/stats/caption) and `heroMedia(_:)` (full-bleed image, no padding)
/// around their own card shell, since the image needs to reach the card's
/// edges while everything else stays padded — a split `RFCard`'s uniform
/// padding can't express.
struct PostSummaryView {
    let item: FeedItem
    let signedURLs: [UUID: URL]
    /// Poster's username, for the avatar + name header. Optional so
    /// call sites that don't have this yet (feed doesn't batch-fetch
    /// authors' profiles) can fall back to a generic label — see the
    /// header's fallback below.
    var posterUsername: String? = nil

    @ViewBuilder
    var textContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item {
        case .exercise(_, let exercise, _):
            dataLine(exerciseDataParts(exercise))
            caption(item.post.caption)
        case .weight(_, let weight, _):
            checkin(value: "\(weight.weightValue.formatted())\(weight.unit.rawValue)", note: item.post.caption)
        case .meal(_, let meal, _):
            dataLine(mealDataParts(meal))
            caption(item.post.caption)
        case .progressPic:
            caption(item.post.caption)
        }
    }

    /// Avatar (rounded-square) + poster name in Bricolage — the loudest
    /// content on the card, per the reference design's "people loud, data
    /// quiet" principle. Post type is conveyed by the content below, not a
    /// colored icon badge.
    private var header: some View {
        HStack(spacing: 10) {
            RFAvatar(username: posterUsername ?? "?", size: 34)

            Text(posterUsername ?? "Someone")
                .font(.rfHeadline)
                .foregroundStyle(Color.rfTextPrimary)

            Spacer()

            Text(item.post.createdAt, style: .relative)
                .font(.rfData)
                .foregroundStyle(Color.rfTextSecondary)
        }
    }

    private func exerciseDataParts(_ exercise: PostExercise) -> [String] {
        var parts: [String] = [exercise.activityType.capitalized]
        if let duration = exercise.durationMinutes { parts.append("\(duration) min") }
        if let calories = exercise.caloriesBurned { parts.append("\(calories) cal") }
        if exercise.source == .healthkit { parts.append("from Apple Health") }
        return parts
    }

    private func mealDataParts(_ meal: PostMeal) -> [String] {
        var parts: [String] = []
        if let name = meal.mealName, !name.isEmpty { parts.append(name) }
        if let calories = meal.calories { parts.append("\(calories) kcal") }
        if let protein = meal.proteinGrams { parts.append("\(Int(protein))p") }
        if let carbs = meal.carbsGrams { parts.append("\(Int(carbs))c") }
        if let fat = meal.fatGrams { parts.append("\(Int(fat))f") }
        return parts
    }

    /// A single quiet mono line joined with " · " — replaces the previous
    /// colored stat-pill badges. Matches the reference design's
    /// `<span class="data">45 min · 6 exercises · from Apple Health</span>`.
    @ViewBuilder
    private func dataLine(_ parts: [String]) -> some View {
        if !parts.isEmpty {
            Text(parts.joined(separator: " · "))
                .font(.rfData)
                .foregroundStyle(Color.rfTextSecondary)
        }
    }

    /// The "quiet checkin" treatment for weight posts — a bordered box with
    /// a large mono number and a small note, not a bare bold number.
    private func checkin(value: String, note: String?) -> some View {
        HStack(spacing: 14) {
            Text(value)
                .font(.custom("DM Mono", size: 19))
                .foregroundStyle(Color.rfTextPrimary)
            if let note, !note.isEmpty {
                Text(note)
                    .font(.rfSubheadline)
                    .foregroundStyle(Color.rfTextSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.rfHairline, lineWidth: 1)
        )
    }

    @ViewBuilder
    private func caption(_ text: String?) -> some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.rfBody)
                .foregroundStyle(Color.rfTextPrimary)
        }
    }

    /// Instagram-style full-bleed hero: one image, or a swipeable paged
    /// carousel with dot indicators when a post has more than one. No
    /// horizontal padding/corner radius here — the enclosing card clips its
    /// own shape, so this can run edge-to-edge to the card's sides.
    ///
    /// Capped at `RFMetrics.heroMediaMaxHeight` rather than a true 1:1
    /// square: a full-width square photo on a modern phone is tall enough
    /// that the reaction/comment row below it sits off-screen with no cue
    /// more content follows. A capped height keeps the image large and
    /// full-bleed while leaving the actions row visible without scrolling
    /// on most posts.
    ///
    /// Deliberately avoids `GeometryReader`: nested inside a `LazyVStack` in
    /// a `ScrollView`, a reader here was swallowing the scroll gesture.
    /// `.frame(maxWidth: .infinity)` + a fixed height + `.clipped()` gets
    /// the same full-bleed crop from the width SwiftUI already provides, no
    /// geometry plumbing required.
    @ViewBuilder
    func heroMedia(_ media: [PostMedia]) -> some View {
        if !media.isEmpty {
            if media.count == 1 {
                mediaImage(for: media[0])
            } else {
                ZStack(alignment: .bottom) {
                    TabView {
                        ForEach(media) { item in
                            mediaImage(for: item)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: RFMetrics.heroMediaMaxHeight)

                    HStack(spacing: 5) {
                        ForEach(media.indices, id: \.self) { _ in
                            Circle()
                                .fill(.white)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.black.opacity(0.35)))
                    .padding(.bottom, 12)
                }
            }
        }
    }

    /// A hard-bounded box, outermost `ZStack` sized first and clipped last,
    /// so the crop never depends on `AsyncImage`/`Image` correctly reporting
    /// (or honoring) their own intrinsic size — verified to render
    /// differently across iOS versions when the frame was applied to the
    /// image/AsyncImage instead of an outer container. A `ZStack` with an
    /// explicit `.frame` and `.clipped()` establishes a boundary no child
    /// can push past, regardless of what that child asks for.
    @ViewBuilder
    private func mediaImage(for item: PostMedia) -> some View {
        ZStack {
            if let url = signedURLs[item.id] {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Color.rfTextSecondary.opacity(0.15)
                    default:
                        Color.rfTextSecondary.opacity(0.15)
                            .overlay(ProgressView())
                    }
                }
            } else {
                Color.rfTextSecondary.opacity(0.15)
                    .overlay(ProgressView())
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: RFMetrics.heroMediaMaxHeight)
        .clipped()
    }
}

private struct FeedItemCard: View {
    let item: FeedItem
    let signedURLs: [UUID: URL]
    let posterUsername: String?
    let reactions: [PostReaction]
    let commentCount: Int
    let currentUserID: UUID
    let onToggleReaction: (ReactionKind) -> Void
    let onOpenDetail: () -> Void

    private var summary: PostSummaryView {
        PostSummaryView(item: item, signedURLs: signedURLs, posterUsername: posterUsername)
    }

    /// Builds the card shell directly instead of using `RFCard` — the hero
    /// image needs to run edge-to-edge to the card's rounded corners with
    /// no padding (Instagram-style), while the header/stats/caption/actions
    /// above and below stay padded. `RFCard`'s uniform padding can't express
    /// that split, so this mirrors its background/corner/shadow by hand.
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summary.textContent
                .padding(.horizontal, RFMetrics.cardPadding)
                .padding(.top, RFMetrics.cardPadding)
                .padding(.bottom, item.media.isEmpty ? RFMetrics.cardPadding : 12)

            summary.heroMedia(item.media)

            Divider()
                .overlay(Color.rfHairline)
                .padding(.horizontal, RFMetrics.cardPadding)
                .padding(.top, item.media.isEmpty ? 0 : 12)

            HStack {
                RFReactionBar(
                    reactions: reactions,
                    currentUserID: currentUserID,
                    onToggle: onToggleReaction
                )

                Spacer()

                Button(action: onOpenDetail) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                        Text(commentCount > 0 ? "\(commentCount)" : "Comment")
                    }
                    .font(.rfData)
                    .foregroundStyle(Color.rfTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, RFMetrics.cardPadding)
            .padding(.vertical, RFMetrics.cardPadding)
        }
        .background(
            RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous)
                .fill(Color.rfSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous)
                .strokeBorder(Color.rfHairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous))
        .shadow(
            color: .black.opacity(RFMetrics.cardShadowOpacity),
            radius: RFMetrics.cardShadowRadius,
            x: 0,
            y: 2
        )
        .onTapGesture(perform: onOpenDetail)
    }
}

#Preview {
    FeedView(viewModel: PostsViewModel(currentUserID: UUID()))
}
