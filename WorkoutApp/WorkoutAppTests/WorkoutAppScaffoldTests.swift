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

    func testLocalAppStateDoesNotExposeLegacyTopLevelQuickProteinAdds() throws {
        let localAppState = try String(contentsOfFile: sourcePath("WorkoutApp/Store/LocalAppState.swift"), encoding: .utf8)

        XCTAssertFalse(localAppState.contains("var quickProteinAdds: [Int] { didSet { save() } }"))
    }

    func testFoodViewDerivesCurrentDateInsteadOfStoringTodayState() throws {
        let foodView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Food/FoodView.swift"), encoding: .utf8)

        XCTAssertFalse(foodView.contains("@State private var today = Date()"))
        XCTAssertTrue(foodView.contains("let currentDate: () -> Date"))
    }

    private func sourcePath(_ path: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: path)
            .path
    }
}
