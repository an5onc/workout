import SwiftUI

struct FoodView: View {
    let state: LocalAppState

    private var selectedMeals: [MealTemplate] {
        state.selectedMeals(from: ProgramSeed.mealTemplates)
    }

    private var selectedMealProteinTotal: Int {
        selectedMeals.reduce(0) { $0 + $1.proteinGrams }
    }

    private var totalProtein: Int {
        ProteinTracker.totalProtein(meals: selectedMeals, quickAdds: state.quickProteinAdds)
    }

    private var proteinProgress: Double {
        ProteinTracker.progress(total: totalProtein, target: ProgramSeed.nutritionTargets.proteinGrams)
    }

    var body: some View {
        NavigationStack {
            List {
                targetSection
                quickProteinSection
                selectedMealsSection
            }
            .navigationTitle("Food")
        }
    }

    private var targetSection: some View {
        Section("Daily target") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(ProgramSeed.nutritionTargets.calories) calories")
                            .font(.title2.bold())
                        Text("\(ProgramSeed.nutritionTargets.proteinGrams)g protein target")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(totalProtein)g")
                        .font(.title.bold())
                        .foregroundStyle(AppTheme.accent)
                }

                ProgressView(value: proteinProgress)
                    .tint(AppTheme.accent)

                Text("\(selectedMealProteinTotal)g from selected meals + \(quickProteinTotal)g quick adds")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            LabeledContent("Fat", value: "\(ProgramSeed.nutritionTargets.fatGrams)g")
            LabeledContent("Carbs", value: "\(ProgramSeed.nutritionTargets.carbsGrams)g")
            LabeledContent("Water", value: "\(ProgramSeed.nutritionTargets.waterOunces) oz")
        }
    }

    private var quickProteinSection: some View {
        Section("Quick protein") {
            HStack {
                ForEach([10, 20, 25], id: \.self) { grams in
                    Button("+\(grams)g") {
                        state.quickProteinAdds.append(grams)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)

            if state.quickProteinAdds.isEmpty {
                Text("No quick protein added")
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent("Quick add total", value: "\(quickProteinTotal)g")

                Button("Remove last quick add") {
                    _ = state.quickProteinAdds.popLast()
                }

                Button("Clear quick adds", role: .destructive) {
                    state.quickProteinAdds.removeAll()
                }
            }
        }
    }

    private var selectedMealsSection: some View {
        Section("Selected meals") {
            if selectedMeals.isEmpty {
                Text("Choose meals in Grocery to populate today's food plan.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(selectedMeals) { meal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.name)
                                    .font(.headline)
                                Text(mealKindTitle(meal.kind))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Spacer()
                            Text("\(meal.proteinGrams)g")
                                .font(.headline)
                        }

                        Text(meal.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            macroLabel("\(meal.calories)", "cal")
                            macroLabel("\(meal.proteinGrams)g", "protein")
                            macroLabel("\(meal.fatGrams)g", "fat")
                            macroLabel("\(meal.carbsGrams)g", "carbs")
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var quickProteinTotal: Int {
        state.quickProteinAdds.reduce(0, +)
    }

    private func macroLabel(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mealKindTitle(_ kind: MealKind) -> String {
        switch kind {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .preWorkout: "Pre-workout"
        case .postWorkout: "Post-workout"
        }
    }
}
