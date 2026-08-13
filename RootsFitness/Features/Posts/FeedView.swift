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
struct PostSummaryView: View {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

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

            caption(item.post.caption)
            mediaGrid(item.media)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(badgeTint.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: badgeIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(badgeTint)
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

    @ViewBuilder
    private func mediaGrid(_ media: [PostMedia]) -> some View {
        if !media.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(media) { item in
                        mediaThumbnail(for: item)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func mediaThumbnail(for item: PostMedia) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Group {
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
        .frame(width: 220, height: 220)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Color.rfTextSecondary.opacity(0.08), lineWidth: 1))
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

    var body: some View {
        RFCard {
            VStack(alignment: .leading, spacing: 12) {
                PostSummaryView(item: item, signedURLs: signedURLs)

                Divider()
                    .overlay(Color.rfTextSecondary.opacity(0.1))

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
            }
        }
        .onTapGesture(perform: onOpenDetail)
    }
}

#Preview {
    FeedView(viewModel: PostsViewModel(currentUserID: UUID()))
}
