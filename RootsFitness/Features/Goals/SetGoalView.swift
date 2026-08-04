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
            Form {
                Section {
                    Picker("Type", selection: $type) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Target (optional)") {
                    TextField("Target value (e.g. weight in lb)", text: $targetValueText)
                        .keyboardType(.decimalPad)

                    Toggle("Set a target date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target date", selection: $targetDate, displayedComponents: .date)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
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
                    }
                }
            }
            .onAppear(perform: prefillFromCurrentGoal)
        }
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
