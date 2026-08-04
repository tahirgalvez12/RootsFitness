import SwiftUI

struct FeedView: View {
    @State var viewModel: PostsViewModel
    @State private var showNewPost = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.feedItems.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Posts Yet",
                        systemImage: "figure.run",
                        description: Text("Friends' workouts, meals, and progress will show up here.")
                    )
                } else {
                    List(viewModel.feedItems) { item in
                        FeedItemRow(item: item, signedURLs: viewModel.signedURLs)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showNewPost = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewPost) {
                NewPostView(viewModel: viewModel)
            }
            .task {
                await viewModel.refresh()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

private struct FeedItemRow: View {
    let item: FeedItem
    let signedURLs: [UUID: URL]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            switch item {
            case .exercise(let post, let exercise, let media):
                header(post: post, icon: "figure.run", title: exercise.activityType.capitalized)
                exerciseDetail(exercise)
                caption(post.caption)
                mediaRow(media)
            case .weight(let post, let weight, let media):
                header(post: post, icon: "scalemass", title: "Weigh-in")
                Text("\(weight.weightValue.formatted()) \(weight.unit.rawValue)")
                    .font(.subheadline)
                caption(post.caption)
                mediaRow(media)
            case .meal(let post, let meal, let media):
                header(post: post, icon: "fork.knife", title: meal.mealName ?? "Meal")
                mealDetail(meal)
                caption(post.caption)
                mediaRow(media)
            case .progressPic(let post, let media):
                header(post: post, icon: "camera", title: "Progress Pic")
                caption(post.caption)
                mediaRow(media)
            }
        }
        .padding(.vertical, 6)
    }

    private func header(post: Post, icon: String, title: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.headline)
            Spacer()
            Text(post.createdAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func exerciseDetail(_ exercise: PostExercise) -> some View {
        HStack(spacing: 12) {
            if let duration = exercise.durationMinutes {
                Label("\(duration) min", systemImage: "clock")
            }
            if let calories = exercise.caloriesBurned {
                Label("\(calories) cal", systemImage: "flame")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func mealDetail(_ meal: PostMeal) -> some View {
        HStack(spacing: 12) {
            if let calories = meal.calories {
                Text("\(calories) cal")
            }
            if let protein = meal.proteinGrams {
                Text("P: \(Int(protein))g")
            }
            if let carbs = meal.carbsGrams {
                Text("C: \(Int(carbs))g")
            }
            if let fat = meal.fatGrams {
                Text("F: \(Int(fat))g")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private func caption(_ text: String?) -> some View {
        if let text, !text.isEmpty {
            Text(text)
                .font(.body)
        }
    }

    @ViewBuilder
    private func mediaRow(_ media: [PostMedia]) -> some View {
        if !media.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(media) { item in
                        if let url = signedURLs[item.id] {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .failure:
                                    Color.gray.opacity(0.2)
                                default:
                                    ProgressView()
                                }
                            }
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.gray.opacity(0.2))
                                .frame(width: 160, height: 160)
                                .overlay(ProgressView())
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    FeedView(viewModel: PostsViewModel(currentUserID: UUID()))
}
