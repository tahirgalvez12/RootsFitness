import SwiftUI

struct GoalsView: View {
    @State var viewModel: GoalsViewModel
    @State private var showSetGoal = false
    @State private var showEndGoalConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.currentGoal == nil && viewModel.history.isEmpty && !viewModel.isLoading {
                    ContentUnavailableView(
                        "No Goals Set",
                        systemImage: "target",
                        description: Text("Set a goal like losing weight, bulking, or general fitness.")
                    )
                } else {
                    List {
                        if let goal = viewModel.currentGoal {
                            Section("Current Goal") {
                                GoalRow(goal: goal)
                                Button("Edit Goal") { showSetGoal = true }
                                Button("End Goal", role: .destructive) { showEndGoalConfirm = true }
                            }
                        } else {
                            Section {
                                Button("Set a Goal") { showSetGoal = true }
                            }
                        }

                        if !viewModel.history.isEmpty {
                            Section("History") {
                                ForEach(viewModel.history) { goal in
                                    GoalRow(goal: goal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSetGoal = true
                    } label: {
                        Image(systemName: "plus")
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
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

private struct GoalRow: View {
    let goal: Goal

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(goal.type.displayName)
                .font(.headline)
            if let targetValue = goal.targetValue {
                Text("Target: \(targetValue.formatted())")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let targetDate = goal.targetDate {
                Text("By \(targetDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    GoalsView(viewModel: GoalsViewModel(currentUserID: UUID()))
}
