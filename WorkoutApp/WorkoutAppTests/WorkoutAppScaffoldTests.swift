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
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"))

        XCTAssertTrue(rootTabView.contains("FoodView(state: state)"))
        XCTAssertTrue(rootTabView.contains("GroceryView(state: state)"))
    }

    private func sourcePath(_ path: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: path)
            .path
    }
}
