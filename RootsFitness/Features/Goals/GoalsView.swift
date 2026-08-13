import SwiftUI

struct GoalsView: View {
    @State var viewModel: GoalsViewModel
    @State private var showSetGoal = false
    @State private var showEndGoalConfirm = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                if viewModel.currentGoal == nil && viewModel.history.isEmpty && !viewModel.isLoading {
                    RFEmptyState(
                        icon: "target",
                        title: "No Goals Set",
                        message: "Set a goal like losing weight, bulking, or general fitness.",
                        actionTitle: "Set a Goal"
                    ) {
                        showSetGoal = true
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let goal = viewModel.currentGoal {
                                sectionLabel("Current Goal")
                                CurrentGoalCard(
                                    goal: goal,
                                    onEdit: { showSetGoal = true },
                                    onEnd: { showEndGoalConfirm = true }
                                )
                            } else {
                                RFPrimaryButton(title: "Set a Goal") {
                                    showSetGoal = true
                                }
                            }

                            if !viewModel.history.isEmpty {
                                sectionLabel("History")
                                VStack(spacing: 10) {
                                    ForEach(viewModel.history) { goal in
                                        HistoryGoalRow(goal: goal)
                                    }
                                }
                            }
                        }
                        .padding(RFMetrics.screenPadding)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSetGoal = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.rfAccent)
                    }
                }
            }
            .sheet(isPresented: $showSetGoal) {
                SetGoalView(viewModel: viewModel)
            }
            .alert("End current goal?", isPresented: $showEndGoalConfirm) {
                Button("End Goal", role: .destructive) {
                    Task { await viewModel.endGoal() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This moves your current goal to history. You can set a new one anytime.")
            }
            .task {
                await viewModel.refresh()
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.rfCaption)
            .foregroundStyle(Color.rfTextSecondary)
    }
}

private struct CurrentGoalCard: View {
    let goal: Goal
    let onEdit: () -> Void
    let onEnd: () -> Void

    var body: some View {
        RFCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.type.displayName)
                        .font(.rfTitle)
                        .foregroundStyle(Color.rfTextPrimary)
                    if let targetValue = goal.targetValue {
                        Text("Target \(targetValue.formatted())")
                            .font(.rfData)
                            .foregroundStyle(Color.rfTextSecondary)
                    }
                    if let targetDate = goal.targetDate {
                        Text("By \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.rfData)
                            .foregroundStyle(Color.rfTextSecondary)
                    }
                }

                HStack(spacing: 10) {
                    RFSecondaryButton(title: "Edit", action: onEdit)
                    RFSecondaryButton(title: "End Goal", role: .destructive, action: onEnd)
                }
            }
        }
    }
}

private struct HistoryGoalRow: View {
    let goal: Goal

    var body: some View {
        RFCard(padding: 14) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.type.displayName)
                        .font(.rfHeadline)
                        .foregroundStyle(Color.rfTextPrimary)
                    if let targetValue = goal.targetValue {
                        Text("Target \(targetValue.formatted())")
                            .font(.rfData)
                            .foregroundStyle(Color.rfTextSecondary)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    GoalsView(viewModel: GoalsViewModel(currentUserID: UUID()))
}
