import SwiftUI

struct HealthSyncView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: HealthSyncViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                if viewModel.isSyncing {
                    ProgressView("Checking Health…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.candidates.isEmpty {
                    RFEmptyState(
                        icon: "heart.text.square.fill",
                        title: "No New Workouts",
                        message: "Workouts you've already shared won't show up again. Tap Sync to check for new ones."
                    )
                    #if DEBUG
                    .overlay(alignment: .bottom) {
                        Button("Seed Debug Workout") {
                            Task {
                                try? await HealthKitManager().seedDebugWorkout()
                                await viewModel.sync()
                            }
                        }
                        .font(.rfCaption)
                        .foregroundStyle(Color.rfTextSecondary)
                        .padding(.bottom, 40)
                    }
                    #endif
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.rfCaption)
                                    .foregroundStyle(.red)
                            }
                            ForEach(viewModel.candidates) { candidate in
                                CandidateRow(candidate: candidate, viewModel: viewModel)
                            }
                        }
                        .padding(RFMetrics.screenPadding)
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
                        .font(.rfButton)
                        .foregroundStyle(Color.rfAccent)
                        .disabled(!viewModel.candidates.contains { $0.isSelected })
                    } else {
                        Button("Sync") {
                            Task { await viewModel.sync() }
                        }
                        .font(.rfButton)
                        .foregroundStyle(Color.rfAccent)
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
        RFCard {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    viewModel.toggleSelection(for: candidate.id)
                } label: {
                    ZStack {
                        Circle()
                            .fill(candidate.isSelected ? Color.rfAccent : Color.clear)
                            .frame(width: 26, height: 26)
                        Circle()
                            .strokeBorder(candidate.isSelected ? Color.rfAccent : Color.rfTextSecondary.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                        if candidate.isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 6) {
                    Text(candidate.activityDisplayName)
                        .font(.rfHeadline)
                        .foregroundStyle(Color.rfTextPrimary)

                    HStack(spacing: 8) {
                        RFStatPill(icon: "clock.fill", text: "\(candidate.durationMinutes) min", tint: .rfPostType(.exercise))
                        if let calories = candidate.caloriesBurned {
                            RFStatPill(icon: "flame.fill", text: "\(calories) cal", tint: .rfPostType(.exercise))
                        }
                    }

                    Text(candidate.startDate, style: .date)
                        .font(.rfCaption)
                        .foregroundStyle(Color.rfTextSecondary)

                    TextField(
                        "Add a caption (optional)",
                        text: Binding(
                            get: { candidate.caption },
                            set: { viewModel.updateCaption(for: candidate.id, caption: $0) }
                        )
                    )
                    .font(.rfBody)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.rfSurfacePrimary)
                    )
                    .padding(.top, 4)
                }
            }
        }
    }
}

#Preview {
    HealthSyncView(viewModel: HealthSyncViewModel(postsViewModel: PostsViewModel(currentUserID: UUID())))
}
