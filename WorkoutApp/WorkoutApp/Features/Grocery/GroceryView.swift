import SwiftUI

struct GroceryView: View {
    let state: LocalAppState

    private var selectedMeals: [MealTemplate] {
        state.selectedMeals(from: ProgramSeed.mealTemplates)
    }

    private var grocerySections: [GrocerySection] {
        GroceryListGenerator.generate(from: selectedMeals)
    }

    var body: some View {
        NavigationStack {
            List {
                mealPickerSection
                groceryListSection
            }
            .navigationTitle("Grocery")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset", role: .destructive) {
                        state.selectedMealIDs.removeAll()
                        state.checkedGroceryItemIDs.removeAll()
                    }
                    .disabled(state.selectedMealIDs.isEmpty && state.checkedGroceryItemIDs.isEmpty)
                }
            }
        }
    }

    private var mealPickerSection: some View {
        ForEach(MealKind.allCases) { kind in
            let meals = ProgramSeed.mealTemplates.filter { $0.kind == kind }
            if !meals.isEmpty {
                Section(mealKindTitle(kind)) {
                    ForEach(meals) { meal in
                        Toggle(isOn: mealSelectionBinding(for: meal)) {
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

    @ViewBuilder
    private var groceryListSection: some View {
        if grocerySections.isEmpty {
            Section("Grocery list") {
                Text("Select meal templates to generate a grocery list.")
                    .foregroundStyle(.secondary)
            }
        } else {
            ForEach(grocerySections) { section in
                Section(section.category.rawValue) {
                    ForEach(section.items) { item in
                        Button {
                            toggleGroceryItem(item.id)
                        } label: {
                            HStack(alignment: .firstTextBaseline, spacing: 12) {
                                Image(systemName: state.checkedGroceryItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(state.checkedGroceryItemIDs.contains(item.id) ? AppTheme.accent : .secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .foregroundStyle(.primary)
                                    Text(item.quantity)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func mealSelectionBinding(for meal: MealTemplate) -> Binding<Bool> {
        Binding {
            state.selectedMealIDs.contains(meal.id)
        } set: { isSelected in
            if isSelected {
                state.selectedMealIDs.insert(meal.id)
            } else {
                state.selectedMealIDs.remove(meal.id)
            }
        }
    }

    private func toggleGroceryItem(_ id: String) {
        if state.checkedGroceryItemIDs.contains(id) {
            state.checkedGroceryItemIDs.remove(id)
        } else {
            state.checkedGroceryItemIDs.insert(id)
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
