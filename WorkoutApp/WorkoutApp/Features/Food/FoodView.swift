import SwiftUI

struct FoodView: View {
    let state: LocalAppState
    let currentDate: () -> Date

    init(state: LocalAppState, currentDate: @escaping () -> Date = Date.init) {
        self.state = state
        self.currentDate = currentDate
    }

    private var today: Date {
        currentDate()
    }

    private var todaysLog: FoodLog {
        state.foodLog(for: today)
    }

    private var selectedProgram: TrainingProgram {
        state.selectedProgram
    }

    private var checkedMeals: [MealTemplate] {
        state.selectedFoodMeals(from: state.selectedProgram.mealTemplates, date: today)
    }

    private var selectedMealProteinTotal: Int {
        checkedMeals.reduce(0) { $0 + $1.proteinGrams }
    }

    private var totalProtein: Int {
        ProteinTracker.totalProtein(meals: checkedMeals, quickAdds: todaysLog.quickProteinAdds)
    }

    private var proteinProgress: Double {
        ProteinTracker.progress(total: totalProtein, target: selectedProgram.nutritionTargets.proteinGrams)
    }

    var body: some View {
        NavigationStack {
            List {
                targetSection
                quickProteinSection
                mealChecklistSection
                checkedMealsSection
            }
            .navigationTitle("Food")
        }
    }

    private var targetSection: some View {
        Section("Daily target") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(selectedProgram.nutritionTargets.calories) calories")
                            .font(.title2.bold())
                        Text("\(state.selectedProgram.nutritionTargets.proteinGrams)g protein target")
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

            LabeledContent("Fat", value: "\(selectedProgram.nutritionTargets.fatGrams)g")
            LabeledContent("Carbs", value: "\(selectedProgram.nutritionTargets.carbsGrams)g")
            LabeledContent("Water", value: "\(selectedProgram.nutritionTargets.waterOunces) oz")
        }
    }

    private var quickProteinSection: some View {
        Section("Quick protein") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(state.selectedProgram.quickProteinAnchors) { anchor in
                        Button {
                            state.addQuickProtein(anchor.proteinGrams, date: currentDate())
                        } label: {
                            VStack(spacing: 2) {
                                Text(anchor.label)
                                Text("+\(anchor.proteinGrams)g")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.vertical, 4)

            if todaysLog.quickProteinAdds.isEmpty {
                Text("No quick protein added")
                    .foregroundStyle(.secondary)
            } else {
                LabeledContent("Quick add total", value: "\(quickProteinTotal)g")

                Button("Remove last quick add") {
                    state.removeLastQuickProteinAdd(date: currentDate())
                }

                Button("Clear quick adds", role: .destructive) {
                    state.clearQuickProteinAdds(date: currentDate())
                }
            }
        }
    }

    private var mealChecklistSection: some View {
        ForEach(MealKind.allCases) { kind in
            let meals = selectedProgram.mealTemplates.filter { $0.kind == kind }
            if !meals.isEmpty {
                Section(mealKindTitle(kind)) {
                    ForEach(meals) { meal in
                        Toggle(isOn: foodMealBinding(for: meal)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(meal.name)
                                    .font(.headline)
                                Text("\(meal.calories) cal | \(meal.proteinGrams)g protein")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var checkedMealsSection: some View {
        Section("Today's checked meals") {
            if checkedMeals.isEmpty {
                Text("Check meals above to count them toward today's protein.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(checkedMeals) { meal in
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
        todaysLog.quickProteinAdds.reduce(0, +)
    }

    private func foodMealBinding(for meal: MealTemplate) -> Binding<Bool> {
        Binding {
            state.foodLog(for: currentDate()).checkedMealIDs.contains(meal.id)
        } set: { isSelected in
            state.toggleFoodMeal(meal.id, on: isSelected, date: currentDate())
        }
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
