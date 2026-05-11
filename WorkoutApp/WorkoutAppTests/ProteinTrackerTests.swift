import XCTest
@testable import WorkoutApp

final class ProteinTrackerTests: XCTestCase {
    func testProteinTotalCombinesMealsAndQuickAdds() {
        let meals = [
            ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" }!,
            ProgramSeed.mealTemplates.first { $0.name == "Chicken & Rice Power Bowl" }!
        ]
        let total = ProteinTracker.totalProtein(meals: meals, quickAdds: [25, 12])
        XCTAssertEqual(total, 110)
    }

    func testProteinProgressCapsAtOneHundredPercent() {
        XCTAssertEqual(ProteinTracker.progress(total: 200, target: 145), 1.0)
        XCTAssertEqual(ProteinTracker.progress(total: 72, target: 144), 0.5)
    }
}
