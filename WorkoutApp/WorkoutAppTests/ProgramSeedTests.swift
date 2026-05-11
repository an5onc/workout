import XCTest
@testable import WorkoutApp

final class ProgramSeedTests: XCTestCase {
    func testWeeklyScheduleHasSevenDays() {
        XCTAssertEqual(ProgramSeed.weeklySchedule.count, 7)
        XCTAssertEqual(ProgramSeed.workout(for: .monday)?.name, "Lower A")
        XCTAssertEqual(ProgramSeed.workout(for: .thursday)?.isRestDay, true)
        XCTAssertEqual(ProgramSeed.workout(for: .sunday)?.name, "Rest day + meal prep")
    }

    func testLowerAIncludesPlanExercises() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        XCTAssertEqual(lowerA.exercises.map(\.name), [
            "Barbell Hip Thrust",
            "Heel-Elevated Goblet Squat",
            "DB Walking Lunge",
            "Leg Extension Machine",
            "Standing Calf Raise"
        ])
        XCTAssertEqual(lowerA.exercises.first?.sets, 4)
        XCTAssertEqual(lowerA.exercises.first?.repRange, "8-10")
    }

    func testMealTemplatesSupportGroceryBuilder() {
        XCTAssertTrue(ProgramSeed.mealTemplates.contains { $0.name == "Protein Oatmeal" })
        XCTAssertTrue(ProgramSeed.mealTemplates.contains { $0.name == "Chicken & Rice Power Bowl" })
        XCTAssertTrue(ProgramSeed.mealTemplates.allSatisfy { !$0.ingredients.isEmpty })
    }

    func testNutritionTargetsAreTyped() {
        let targets: NutritionTargets = ProgramSeed.nutritionTargets

        XCTAssertEqual(targets.calories, 1600)
        XCTAssertEqual(targets.proteinGrams, 145)
        XCTAssertEqual(targets.fatGrams, 50)
        XCTAssertEqual(targets.carbsGrams, 145)
        XCTAssertEqual(targets.waterOunces, 100)
    }

    func testMealTemplatesIncludeStructuredMacros() throws {
        let oatmeal = try XCTUnwrap(ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" })

        XCTAssertEqual(oatmeal.calories, 410)
        XCTAssertEqual(oatmeal.proteinGrams, 31)
        XCTAssertEqual(oatmeal.fatGrams, 11)
        XCTAssertEqual(oatmeal.carbsGrams, 48)
    }

    func testMealTemplatesIncludeGroceryCategoryAndQuantity() throws {
        let chickenBowl = try XCTUnwrap(ProgramSeed.mealTemplates.first { $0.name == "Chicken & Rice Power Bowl" })
        let chicken = try XCTUnwrap(chickenBowl.ingredients.first { $0.id == "chicken-breast" })

        XCTAssertEqual(chicken.category, .meatSeafood)
        XCTAssertEqual(chicken.quantity, "5 oz")
    }

    func testQuickProteinAnchorsIncludePlanItemsWithLabelsAndGrams() {
        let anchorsByID = Dictionary(uniqueKeysWithValues: ProgramSeed.quickProteinAnchors.map { ($0.id, $0) })

        XCTAssertEqual(anchorsByID["whey"]?.label, "Whey")
        XCTAssertEqual(anchorsByID["whey"]?.proteinGrams, 25)
        XCTAssertEqual(anchorsByID["greek-yogurt"]?.label, "Greek yogurt")
        XCTAssertEqual(anchorsByID["greek-yogurt"]?.proteinGrams, 20)
        XCTAssertEqual(anchorsByID["chicken"]?.label, "Chicken")
        XCTAssertEqual(anchorsByID["chicken"]?.proteinGrams, 30)
        XCTAssertEqual(anchorsByID["eggs"]?.label, "Eggs")
        XCTAssertEqual(anchorsByID["eggs"]?.proteinGrams, 12)
        XCTAssertEqual(anchorsByID["tuna"]?.label, "Tuna")
        XCTAssertEqual(anchorsByID["tuna"]?.proteinGrams, 25)
    }
}
