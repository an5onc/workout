import SwiftUI

struct PlanView: View {
    @State private var exerciseSearchText = ""

    private var filteredExercises: [Exercise] {
        let exercises = exerciseLibrary
        let query = exerciseSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return exercises
        }

        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query)
                || exercise.cue.localizedCaseInsensitiveContains(query)
                || exercise.repRange.localizedCaseInsensitiveContains(query)
        }
    }

    private var exerciseLibrary: [Exercise] {
        var seenIDs = Set<String>()

        return ProgramSeed.weeklySchedule
            .flatMap(\.exercises)
            .filter { exercise in
                seenIDs.insert(exercise.id).inserted
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            List {
                structureSection
                weeklyScheduleSection
                exerciseLibrarySection
                nutritionReferenceSection
                groceryReferenceSection
                sundayPrepSection
            }
            .navigationTitle("Plan")
            .searchable(text: $exerciseSearchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
        }
    }

    private var structureSection: some View {
        Section("12-week structure") {
            planPhase("Weeks 1-4", "Build repeatable form, leave 1-2 reps in reserve, and log baseline loads.")
            planPhase("Weeks 5-8", "Add load or reps when sets land cleanly inside the target range.")
            planPhase("Weeks 9-12", "Keep technique strict, push top sets, then deload after week 12.")
        }
    }

    private var weeklyScheduleSection: some View {
        Section("Weekly schedule") {
            ForEach(ProgramSeed.weeklySchedule) { day in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(weekdayTitle(day.id))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Spacer()
                        Text(day.isRestDay ? "Rest" : "\(day.exercises.count) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(day.name)
                        .font(.headline)

                    Text(day.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
            }
        }
    }

    private var exerciseLibrarySection: some View {
        Section("Exercise library") {
            if filteredExercises.isEmpty {
                Text("No exercises match this search.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredExercises) { exercise in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Sets", value: "\(exercise.sets)")
                            LabeledContent("Reps", value: exercise.repRange)
                            LabeledContent("Rest", value: exercise.rest)

                            Text(exercise.cue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let demoURL = exercise.demoURL {
                                Link("Demo", destination: demoURL)
                            }
                        }
                        .padding(.vertical, 6)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("\(exercise.sets) sets | \(exercise.repRange) | \(exercise.rest)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var nutritionReferenceSection: some View {
        Section("Nutrition reference") {
            LabeledContent("Calories", value: "\(ProgramSeed.nutritionTargets.calories)")
            LabeledContent("Protein", value: "\(ProgramSeed.nutritionTargets.proteinGrams)g")
            LabeledContent("Fat", value: "\(ProgramSeed.nutritionTargets.fatGrams)g")
            LabeledContent("Carbs", value: "\(ProgramSeed.nutritionTargets.carbsGrams)g")
            LabeledContent("Water", value: "\(ProgramSeed.nutritionTargets.waterOunces) oz")

            ForEach(ProgramSeed.mealTemplates) { meal in
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                    Text("\(meal.calories) cal | \(meal.proteinGrams)g protein | \(mealKindTitle(meal.kind))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var groceryReferenceSection: some View {
        Section("Grocery reference") {
            ForEach(groceryCategoriesWithIngredients, id: \.category) { section in
                DisclosureGroup(section.category.rawValue) {
                    ForEach(section.ingredients, id: \.id) { ingredient in
                        LabeledContent(ingredient.name, value: ingredient.quantity)
                    }
                }
            }
        }
    }

    private var sundayPrepSection: some View {
        Section("Sunday prep") {
            prepStep("Cook proteins", "Batch chicken, salmon, eggs, or another lean protein anchor.")
            prepStep("Prep carbs and produce", "Cook rice or potatoes, wash produce, and portion vegetables.")
            prepStep("Stage the week", "Pick meal templates in Grocery, shop once, and keep quick protein available.")
        }
    }

    private var groceryCategoriesWithIngredients: [(category: GroceryCategory, ingredients: [Ingredient])] {
        let ingredientsByCategory = Dictionary(grouping: ProgramSeed.mealTemplates.flatMap(\.ingredients), by: \.category)

        return GroceryCategory.allCases.compactMap { category in
            guard let ingredients = ingredientsByCategory[category], !ingredients.isEmpty else {
                return nil
            }

            return (
                category,
                ingredients.sorted {
                    if $0.name == $1.name {
                        $0.quantity < $1.quantity
                    } else {
                        $0.name < $1.name
                    }
                }
            )
        }
    }

    private func planPhase(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func prepStep(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func weekdayTitle(_ weekday: Weekday) -> String {
        switch weekday {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
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
