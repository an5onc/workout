import XCTest
@testable import WorkoutApp

final class GroceryListGeneratorTests: XCTestCase {
    func testGeneratedListGroupsByCategoryOrderAndOmitsEmptyCategories() {
        let meals = [
            meal("breakfast", [
                ingredient("banana", "Banana", "1", .produce),
                ingredient("oats", "Rolled oats", "1/2 cup", .pantry)
            ]),
            meal("snack", [
                ingredient("whey-first", "Whey protein", "1 scoop", .supplementsExtras)
            ])
        ]

        let sections = GroceryListGenerator.generate(from: meals)

        XCTAssertEqual(sections.map(\.category), [.produce, .pantry, .supplementsExtras])
        XCTAssertFalse(sections.contains { $0.category == .other })
    }

    func testDuplicateIngredientsMergeCaseInsensitivelyAndPreserveFirstOccurrence() {
        let meals = [
            meal("first", [
                ingredient("whey-first", "Whey protein", "1 scoop", .supplementsExtras)
            ]),
            meal("second", [
                ingredient("whey-second", "whey protein", "2 scoops", .supplementsExtras)
            ])
        ]

        let sections = GroceryListGenerator.generate(from: meals)
        let supplements = sections.first { $0.category == .supplementsExtras }
        let whey = supplements?.items.first { $0.name == "Whey protein" }

        XCTAssertEqual(whey?.id, "whey-first")
        XCTAssertEqual(whey?.name, "Whey protein")
        XCTAssertEqual(whey?.quantity, "1 scoop + 2 scoops")
        XCTAssertEqual(whey?.category, .supplementsExtras)
        XCTAssertEqual(supplements?.items.count, 1)
    }

    func testItemsSortCaseInsensitivelyInsideSection() {
        let meals = [
            meal("pantry", [
                ingredient("banana", "Banana chips", "1 bag", .pantry),
                ingredient("almonds", "almonds", "1 cup", .pantry),
                ingredient("cocoa", "cocoa powder", "2 tbsp", .pantry)
            ])
        ]

        let sections = GroceryListGenerator.generate(from: meals)
        let pantry = sections.first { $0.category == .pantry }

        XCTAssertEqual(pantry?.items.map(\.name), ["almonds", "Banana chips", "cocoa powder"])
    }

    private func meal(_ id: String, _ ingredients: [Ingredient]) -> MealTemplate {
        MealTemplate(
            id: id,
            kind: .snack,
            name: id,
            detail: "",
            calories: 0,
            proteinGrams: 0,
            fatGrams: 0,
            carbsGrams: 0,
            ingredients: ingredients
        )
    }

    private func ingredient(_ id: String, _ name: String, _ quantity: String, _ category: GroceryCategory) -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity, category: category)
    }
}
