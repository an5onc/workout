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
}
