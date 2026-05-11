import Foundation

struct GroceryItem: Identifiable, Hashable {
    let id: String
    let name: String
    let quantity: String
    let category: GroceryCategory
}

struct GrocerySection: Identifiable, Hashable {
    var id: GroceryCategory { category }
    let category: GroceryCategory
    let items: [GroceryItem]
}

enum GroceryListGenerator {
    static func generate(from meals: [MealTemplate]) -> [GrocerySection] {
        var merged: [String: GroceryItem] = [:]

        for ingredient in meals.flatMap(\.ingredients) {
            let key = ingredient.name.lowercased()
            if let existing = merged[key] {
                merged[key] = GroceryItem(
                    id: existing.id,
                    name: existing.name,
                    quantity: existing.quantity + " + " + ingredient.quantity,
                    category: existing.category
                )
            } else {
                merged[key] = GroceryItem(
                    id: ingredient.id,
                    name: ingredient.name,
                    quantity: ingredient.quantity,
                    category: ingredient.category
                )
            }
        }

        return GroceryCategory.allCases.compactMap { category in
            let items = merged.values
                .filter { $0.category == category }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            return items.isEmpty ? nil : GrocerySection(category: category, items: items)
        }
    }
}
