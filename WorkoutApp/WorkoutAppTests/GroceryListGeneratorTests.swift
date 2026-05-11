import XCTest
@testable import WorkoutApp

final class GroceryListGeneratorTests: XCTestCase {
    func testGeneratedListGroupsByCategory() {
        let meals = [
            ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" }!,
            ProgramSeed.mealTemplates.first { $0.name == "Chicken & Rice Power Bowl" }!
        ]
        let sections = GroceryListGenerator.generate(from: meals)
        XCTAssertTrue(sections.contains { $0.category == .produce })
        XCTAssertTrue(sections.contains { $0.category == .pantry })
        XCTAssertTrue(sections.contains { $0.category == .meatSeafood })
    }

    func testDuplicateIngredientsMergeQuantitiesByName() {
        let meals = [
            ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" }!,
            ProgramSeed.mealTemplates.first { $0.name == "Protein Shake" }!
        ]
        let sections = GroceryListGenerator.generate(from: meals)
        let supplements = sections.first { $0.category == .supplementsExtras }
        let whey = supplements?.items.first { $0.name == "Whey protein" }
        XCTAssertEqual(whey?.quantity, "1 scoop + 1 scoop")
    }
}
