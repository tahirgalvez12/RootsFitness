import SwiftUI

struct SetGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: GoalsViewModel

    @State private var type: GoalType = .loseWeight
    @State private var targetValueText = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        RFPillPicker(
                            options: GoalType.allCases.map { ($0, $0.displayName) },
                            selection: $type
                        )

                        sectionLabel("Target (optional)")
                        RFCard {
                            VStack(alignment: .leading, spacing: 14) {
                                RFTextField(
                                    title: "Target value (e.g. weight in lb)",
                                    text: $targetValueText,
                                    keyboardType: .decimalPad
                                )

                                Toggle("Set a target date", isOn: $hasTargetDate)
                                    .font(.rfBody)
                                    .tint(Color.rfAccent)

                                if hasTargetDate {
                                    DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                                        .font(.rfBody)
                                        .tint(Color.rfAccent)
                                }
                            }
                        }

                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.rfCaption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(RFMetrics.screenPadding)
                }
            }
            .navigationTitle(viewModel.currentGoal == nil ? "Set a Goal" : "Update Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task { await submit() }
                        }
                        .font(.rfButton)
                        .foregroundStyle(Color.rfAccent)
                    }
                }
            }
            .onAppear(perform: prefillFromCurrentGoal)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.rfCaption)
            .foregroundStyle(Color.rfTextSecondary)
    }

    private func prefillFromCurrentGoal() {
        guard let goal = viewModel.currentGoal else { return }
        type = goal.type
        if let value = goal.targetValue {
            targetValueText = value.formatted()
        }
        if let date = goal.targetDate {
            hasTargetDate = true
            targetDate = date
        }
    }

    private func submit() async {
        let value = Double(targetValueText)
        let date = hasTargetDate ? targetDate : nil
        let success = await viewModel.setGoal(type: type, targetValue: value, targetDate: date)
        if success {
            dismiss()
        }
    }
}

#Preview {
    SetGoalView(viewModel: GoalsViewModel(currentUserID: UUID()))
}
