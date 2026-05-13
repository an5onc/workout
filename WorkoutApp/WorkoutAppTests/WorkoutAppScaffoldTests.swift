import XCTest

final class WorkoutAppScaffoldTests: XCTestCase {
    func testScaffoldLoads() {
        XCTAssertTrue(true)
    }

    func testFoodAndGroceryScreensExist() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourcePath("WorkoutApp/Features/Food/FoodView.swift")))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourcePath("WorkoutApp/Features/Grocery/GroceryView.swift")))
    }

    func testRootTabViewWiresFoodAndGroceryScreens() throws {
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)

        XCTAssertTrue(rootTabView.contains("FoodView(state: state)"))
        XCTAssertTrue(rootTabView.contains("GroceryView(state: state)"))
    }

    func testPlanReferenceScreenExistsAndIsWired() throws {
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)
        let planViewPath = sourcePath("WorkoutApp/Features/Plan/PlanView.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: planViewPath))
        XCTAssertTrue(rootTabView.contains("PlanView()"))

        let planView = try String(contentsOfFile: planViewPath, encoding: .utf8)
        XCTAssertTrue(planView.contains("struct PlanView: View"))
        XCTAssertTrue(planView.contains(".searchable"))
        XCTAssertTrue(planView.contains("Link(\"Demo\""))
        XCTAssertTrue(planView.contains("ProgramSeed.weeklySchedule"))
    }

    func testPlanGroceryReferenceUsesMergedGrocerySections() throws {
        let planView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Plan/PlanView.swift"), encoding: .utf8)

        XCTAssertTrue(planView.contains("GroceryListGenerator.generate(from: ProgramSeed.mealTemplates)"))
        XCTAssertTrue(planView.contains("ForEach(section.items)"))
        XCTAssertFalse(planView.contains("ForEach(section.ingredients"))
    }

    func testLocalAppStateDoesNotExposeLegacyTopLevelQuickProteinAdds() throws {
        let localAppState = try String(contentsOfFile: sourcePath("WorkoutApp/Store/LocalAppState.swift"), encoding: .utf8)

        XCTAssertFalse(localAppState.contains("var quickProteinAdds: [Int] { didSet { save() } }"))
    }

    func testFoodViewDerivesCurrentDateInsteadOfStoringTodayState() throws {
        let foodView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Food/FoodView.swift"), encoding: .utf8)

        XCTAssertFalse(foodView.contains("@State private var today = Date()"))
        XCTAssertTrue(foodView.contains("let currentDate: () -> Date"))
    }

    func testPrepAheadViewExistsAndIsWiredIntoToday() throws {
        let prepAheadPath = sourcePath("WorkoutApp/Features/Today/PrepAheadView.swift")
        let todayView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/TodayView.swift"), encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: prepAheadPath))
        XCTAssertTrue(todayView.contains("selectedPrepAheadOffset"))
        XCTAssertTrue(todayView.contains("ForEach(1...7"))
        XCTAssertTrue(todayView.contains("PrepAheadView(workout: futureWorkout, futureDate: futureDate, state: state)"))
    }

    func testPrepAheadViewDoesNotExposeLiveWorkoutCompletionControls() throws {
        let prepAheadView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/PrepAheadView.swift"), encoding: .utf8)

        XCTAssertFalse(prepAheadView.contains("finishWorkout"))
        XCTAssertFalse(prepAheadView.contains("toggleSet"))
        XCTAssertFalse(prepAheadView.contains("Mark workout finished"))
        XCTAssertFalse(prepAheadView.contains("restTimer"))
        XCTAssertFalse(prepAheadView.contains("ExerciseCardView("))
        XCTAssertTrue(prepAheadView.contains("PrepAheadExerciseCard"))
    }

    private func sourcePath(_ path: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: path)
            .path
    }
}
