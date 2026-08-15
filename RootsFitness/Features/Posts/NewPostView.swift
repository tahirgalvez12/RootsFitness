import PhotosUI
import SwiftUI

struct NewPostView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: PostsViewModel

    @State private var postType: PostType = .exercise
    @State private var caption = ""

    // Exercise
    @State private var activityType = ""
    @State private var durationMinutes = ""
    @State private var caloriesBurned = ""

    // Weight
    @State private var weightValue = ""
    @State private var weightUnit: WeightUnit = AppSettings.shared.preferredWeightUnit

    // Meal
    @State private var mealName = ""
    @State private var mealCalories = ""
    @State private var proteinGrams = ""
    @State private var carbsGrams = ""
    @State private var fatGrams = ""

    // Media
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImageData: Data?

    private var canPost: Bool {
        switch postType {
        case .exercise:
            return !activityType.trimmingCharacters(in: .whitespaces).isEmpty
        case .weight:
            return Double(weightValue) != nil
        case .meal:
            return true
        case .progressPic:
            return selectedImageData != nil
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.rfSurfacePrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        RFPillPicker(
                            options: [
                                (PostType.exercise, "Exercise"),
                                (PostType.weight, "Weight"),
                                (PostType.meal, "Meal"),
                                (PostType.progressPic, "Progress Pic"),
                            ],
                            selection: $postType
                        )

                        if postType != .progressPic {
                            RFCard {
                                VStack(alignment: .leading, spacing: 14) {
                                    switch postType {
                                    case .exercise:
                                        exerciseFields
                                    case .weight:
                                        weightFields
                                    case .meal:
                                        mealFields
                                    case .progressPic:
                                        EmptyView()
                                    }
                                }
                            }
                        }

                        sectionLabel(postType == .progressPic ? "Photo (required)" : "Photo (optional)")
                        photoPicker

                        sectionLabel("Caption")
                        RFCard {
                            TextField("Add a caption (optional)", text: $caption, axis: .vertical)
                                .font(.rfBody)
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
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isPosting {
                        ProgressView()
                    } else {
                        Button("Post") {
                            Task { await submit() }
                        }
                        .font(.rfButton)
                        .foregroundStyle(canPost ? Color.rfAccent : Color.rfTextSecondary)
                        .disabled(!canPost)
                    }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    selectedImageData = try? await newValue?.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.rfCaption)
            .foregroundStyle(Color.rfTextSecondary)
    }

    private var exerciseFields: some View {
        Group {
            RFTextField(title: "Activity (e.g. Running)", text: $activityType)
            RFTextField(title: "Duration (minutes)", text: $durationMinutes, keyboardType: .numberPad)
            RFTextField(title: "Calories burned", text: $caloriesBurned, keyboardType: .numberPad)
        }
    }

    private var weightFields: some View {
        VStack(alignment: .leading, spacing: 14) {
            RFTextField(title: "Weight", text: $weightValue, keyboardType: .decimalPad)
            RFPillPicker(
                options: [(WeightUnit.lb, "lb"), (WeightUnit.kg, "kg")],
                selection: $weightUnit
            )
        }
    }

    private var mealFields: some View {
        Group {
            RFTextField(title: "Meal name", text: $mealName)
            RFTextField(title: "Calories", text: $mealCalories, keyboardType: .numberPad)
            RFTextField(title: "Protein (g)", text: $proteinGrams, keyboardType: .decimalPad)
            RFTextField(title: "Carbs (g)", text: $carbsGrams, keyboardType: .decimalPad)
            RFTextField(title: "Fat (g)", text: $fatGrams, keyboardType: .decimalPad)
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 32, weight: .semibold))
                    Text("Choose Photo")
                        .font(.rfSubheadline)
                }
                .foregroundStyle(Color.rfAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(
                    RoundedRectangle(cornerRadius: RFMetrics.cardCornerRadius, style: .continuous)
                        .strokeBorder(Color.rfAccent.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func submit() async {
        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let captionValue = trimmedCaption.isEmpty ? nil : trimmedCaption
        let success: Bool

        switch postType {
        case .exercise:
            success = await viewModel.createExercisePost(
                caption: captionValue,
                input: NewExerciseInput(
                    activityType: activityType.trimmingCharacters(in: .whitespaces),
                    durationMinutes: Int(durationMinutes),
                    caloriesBurned: Int(caloriesBurned)
                ),
                imageData: selectedImageData
            )
        case .weight:
            guard let value = Double(weightValue) else { return }
            success = await viewModel.createWeightPost(
                caption: captionValue,
                input: NewWeightInput(weightValue: value, unit: weightUnit),
                imageData: selectedImageData
            )
        case .meal:
            let trimmedName = mealName.trimmingCharacters(in: .whitespaces)
            success = await viewModel.createMealPost(
                caption: captionValue,
                input: NewMealInput(
                    mealName: trimmedName.isEmpty ? nil : trimmedName,
                    calories: Int(mealCalories),
                    proteinGrams: Double(proteinGrams),
                    carbsGrams: Double(carbsGrams),
                    fatGrams: Double(fatGrams)
                ),
                imageData: selectedImageData
            )
        case .progressPic:
            guard let imageData = selectedImageData else { return }
            success = await viewModel.createProgressPicPost(caption: captionValue, imageData: imageData)
        }

        if success {
            dismiss()
        }
    }
}

#Preview {
    NewPostView(viewModel: PostsViewModel(currentUserID: UUID()))
}
