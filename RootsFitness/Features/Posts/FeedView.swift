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

    private var badgeIcon: String {
        switch item {
        case .exercise: return "figure.run"
        case .weight: return "scalemass.fill"
        case .meal: return "fork.knife"
        case .progressPic: return "camera.fill"
        }
    }

    private var badgeTint: Color {
        .rfPostType(item.post.type)
    }

    private var title: String {
        switch item {
        case .exercise(_, let exercise, _): return exercise.activityType.capitalized
        case .weight: return "Weigh-in"
        case .meal(_, let meal, _): return meal.mealName?.isEmpty == false ? meal.mealName! : "Meal"
        case .progressPic: return "Progress Pic"
        }
    }

    @ViewBuilder
    var textContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            statsSection
            caption(item.post.caption)
        }
    }

    @ViewBuilder
    private var statsSection: some View {
        switch item {
        case .exercise(_, let exercise, _):
            exerciseStats(exercise)
        case .weight(_, let weight, _):
            Text("\(weight.weightValue.formatted()) \(weight.unit.rawValue)")
                .font(.rfTitle)
                .foregroundStyle(Color.rfTextPrimary)
        case .meal(_, let meal, _):
            mealStats(meal)
        case .progressPic:
            EmptyView()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badgeTint)
                    .frame(width: 40, height: 40)
                Image(systemName: badgeIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.rfHeadline)
                .foregroundStyle(Color.rfTextPrimary)

            Spacer()

            Text(item.post.createdAt, style: .relative)
                .font(.rfCaption)
                .foregroundStyle(Color.rfTextSecondary)
        }
    }

    private func exerciseStats(_ exercise: PostExercise) -> some View {
        HStack(spacing: 8) {
            if let duration = exercise.durationMinutes {
                RFStatPill(icon: "clock.fill", text: "\(duration) min", tint: .rfPostType(.exercise))
            }
            if let calories = exercise.caloriesBurned {
                RFStatPill(icon: "flame.fill", text: "\(calories) cal", tint: .rfPostType(.exercise))
            }
            if exercise.source == .healthkit {
                RFStatPill(icon: "heart.fill", text: "Health", tint: .rfPostType(.exercise))
            }
        }
    }

    private func mealStats(_ meal: PostMeal) -> some View {
        HStack(spacing: 8) {
            if let calories = meal.calories {
                RFStatPill(icon: "flame.fill", text: "\(calories) cal", tint: .rfPostType(.meal))
            }
            if let protein = meal.proteinGrams {
                RFStatPill(icon: "p.circle.fill", text: "\(Int(protein))g", tint: .rfPostType(.meal))
            }
            if let carbs = meal.carbsGrams {
                RFStatPill(icon: "c.circle.fill", text: "\(Int(carbs))g", tint: .rfPostType(.meal))
            }
            if let fat = meal.fatGrams {
                RFStatPill(icon: "f.circle.fill", text: "\(Int(fat))g", tint: .rfPostType(.meal))
            }
        }
    }

    @ViewBuilder
    private func caption(_ text: String?) -> some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.rfBody)
                .foregroundStyle(Color.rfTextPrimary)
        }
    }

    /// Instagram-style full-bleed hero: one square image, or a swipeable
    /// paged carousel with dot indicators when a post has more than one.
    /// No horizontal padding/corner radius here — the enclosing card clips
    /// its own shape, so this can run edge-to-edge to the card's sides.
    /// Deliberately avoids `GeometryReader`: nested inside a `LazyVStack` in
    /// a `ScrollView`, a reader here was swallowing the scroll gesture.
    /// `.aspectRatio(1, contentMode: .fill)` + `.clipped()` derives a square
    /// purely from the width SwiftUI already gives this view, no geometry
    /// plumbing required.
    @ViewBuilder
    func heroMedia(_ media: [PostMedia]) -> some View {
        if !media.isEmpty {
            if media.count == 1 {
                mediaImage(for: media[0])
                    .aspectRatio(1, contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                ZStack(alignment: .bottom) {
                    TabView {
                        ForEach(media) { item in
                            mediaImage(for: item)
                                .aspectRatio(1, contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)

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

    @ViewBuilder
    private func mediaImage(for item: PostMedia) -> some View {
        if let url = signedURLs[item.id] {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.rfTextSecondary.opacity(0.15)
                default:
                    ProgressView()
                }
            }
        } else {
            Color.rfTextSecondary.opacity(0.15)
                .overlay(ProgressView())
        }
    }
}

private struct FeedItemCard: View {
    let item: FeedItem
    let signedURLs: [UUID: URL]
    let reactions: [PostReaction]
    let commentCount: Int
    let currentUserID: UUID
    let onToggleReaction: (ReactionKind) -> Void
    let onOpenDetail: () -> Void

    private var summary: PostSummaryView {
        PostSummaryView(item: item, signedURLs: signedURLs)
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
                .overlay(Color.rfTextSecondary.opacity(0.1))
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
                        Image(systemName: "bubble.left.fill")
                        Text(commentCount > 0 ? "\(commentCount)" : "Comment")
                    }
                    .font(.rfCaption)
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
        .clipShape(RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous))
        .shadow(
            color: .black.opacity(RFMetrics.cardShadowOpacity),
            radius: RFMetrics.cardShadowRadius,
            x: 0,
            y: 4
        )
        .onTapGesture(perform: onOpenDetail)
    }
}

#Preview {
    FeedView(viewModel: PostsViewModel(currentUserID: UUID()))
}
