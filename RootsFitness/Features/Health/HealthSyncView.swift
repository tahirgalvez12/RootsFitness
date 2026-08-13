import SwiftUI

struct HealthSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: HealthSyncViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isSyncing {
                    ProgressView("Checking Health…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.candidates.isEmpty {
                    ContentUnavailableView {
                        Label("No New Workouts", systemImage: "heart.text.square")
                    } description: {
                        Text("Workouts you've already shared won't show up again. Tap Sync to check for new ones.")
                    } actions: {
                        #if DEBUG
                        Button("Seed Debug Workout") {
                            Task {
                                try? await HealthKitManager().seedDebugWorkout()
                                await viewModel.sync()
                            }
                        }
                        #endif
                    }
                } else {
                    List {
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                        ForEach(viewModel.candidates) { candidate in
                            CandidateRow(candidate: candidate, viewModel: viewModel)
                        }
                    }
                }
            }
            .navigationTitle("Sync from Health")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isPosting {
                        ProgressView()
                    } else if !viewModel.candidates.isEmpty {
                        Button("Post Selected") {
                            Task { await viewModel.postSelected() }
                        }
                        .disabled(!viewModel.candidates.contains { $0.isSelected })
                    } else {
                        Button("Sync") {
                            Task { await viewModel.sync() }
                        }
                    }
                }
            }
            .task {
                await viewModel.sync()
            }
        }
    }
}

private struct CandidateRow: View {
    let candidate: HealthWorkoutCandidate
    let viewModel: HealthSyncViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                viewModel.toggleSelection(for: candidate.id)
            } label: {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(candidate.isSelected ? .blue : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(candidate.activityDisplayName)
                    .font(.headline)
                HStack(spacing: 12) {
                    Text("\(candidate.durationMinutes) min")
                    if let calories = candidate.caloriesBurned {
                        Text("\(calories) cal")
                    }
                    Text(candidate.startDate, style: .date)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                TextField(
                    "Add a caption (optional)",
                    text: Binding(
                        get: { candidate.caption },
                        set: { viewModel.updateCaption(for: candidate.id, caption: $0) }
                    )
                )
                .font(.subheadline)
                .textFieldStyle(.roundedBorder)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HealthSyncView(viewModel: HealthSyncViewModel(postsViewModel: PostsViewModel(currentUserID: UUID())))
}
