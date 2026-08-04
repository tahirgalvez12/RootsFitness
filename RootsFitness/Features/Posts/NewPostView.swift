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
    @State private var weightUnit: WeightUnit = .lb

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
            Form {
                Section {
                    Picker("Type", selection: $postType) {
                        Text("Exercise").tag(PostType.exercise)
                        Text("Weight").tag(PostType.weight)
                        Text("Meal").tag(PostType.meal)
                        Text("Progress Pic").tag(PostType.progressPic)
                    }
                    .pickerStyle(.segmented)
                }

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

                Section("Photo\(postType == .progressPic ? " (required)" : " (optional)")") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Label("Choose Photo", systemImage: "photo")
                        }
                    }
                }

                Section("Caption") {
                    TextField("Add a caption (optional)", text: $caption, axis: .vertical)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
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

    private var exerciseFields: some View {
        Section("Exercise") {
            TextField("Activity (e.g. Running)", text: $activityType)
            TextField("Duration (minutes)", text: $durationMinutes)
                .keyboardType(.numberPad)
            TextField("Calories burned", text: $caloriesBurned)
                .keyboardType(.numberPad)
        }
    }

    private var weightFields: some View {
        Section("Weight") {
            TextField("Weight", text: $weightValue)
                .keyboardType(.decimalPad)
            Picker("Unit", selection: $weightUnit) {
                Text("lb").tag(WeightUnit.lb)
                Text("kg").tag(WeightUnit.kg)
            }
            .pickerStyle(.segmented)
        }
    }

    private var mealFields: some View {
        Section("Meal") {
            TextField("Meal name", text: $mealName)
            TextField("Calories", text: $mealCalories)
                .keyboardType(.numberPad)
            TextField("Protein (g)", text: $proteinGrams)
                .keyboardType(.decimalPad)
            TextField("Carbs (g)", text: $carbsGrams)
                .keyboardType(.decimalPad)
            TextField("Fat (g)", text: $fatGrams)
                .keyboardType(.decimalPad)
        }
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
