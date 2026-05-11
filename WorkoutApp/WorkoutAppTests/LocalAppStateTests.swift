import XCTest
@testable import WorkoutApp

@MainActor
final class LocalAppStateTests: XCTestCase {
    private let storageKey = "workout.localAppState.v1"
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "LocalAppStateTests.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        try super.tearDownWithError()
    }

    func testRoundTripRestoreOfAllPersistedFields() {
        let state = LocalAppState(defaults: defaults)
        state.selectedDayOverride = .friday
        state.setProgress = [
            SetProgress(exerciseID: "hip-thrust", completedSets: [0, 2], weightText: "135", repsText: "10", rpeText: "8")
        ]
        state.selectedMealIDs = ["breakfast-a", "dinner-b"]
        state.checkedGroceryItemIDs = ["eggs", "rice"]
        state.quickProteinAdds = [25, 40]

        let restored = LocalAppState(defaults: defaults)

        XCTAssertEqual(restored.selectedDayOverride, .friday)
        XCTAssertEqual(restored.setProgress, state.setProgress)
        XCTAssertEqual(restored.selectedMealIDs, ["breakfast-a", "dinner-b"])
        XCTAssertEqual(restored.checkedGroceryItemIDs, ["eggs", "rice"])
        XCTAssertEqual(restored.quickProteinAdds, [25, 40])
    }

    func testToggleSetPersistsAndTogglesOff() {
        let state = LocalAppState(defaults: defaults)

        state.toggleSet(exerciseID: "hip-thrust", setIndex: 1)
        var restored = LocalAppState(defaults: defaults)
        XCTAssertEqual(restored.progress(for: "hip-thrust").completedSets, [1])

        restored.toggleSet(exerciseID: "hip-thrust", setIndex: 1)
        restored = LocalAppState(defaults: defaults)
        XCTAssertEqual(restored.progress(for: "hip-thrust").completedSets, [])
    }

    func testSelectedMealsFiltersBySelectedMealIDs() {
        let state = LocalAppState(defaults: defaults)
        state.selectedMealIDs = ["meal-2"]
        let templates = [
            meal(id: "meal-1"),
            meal(id: "meal-2"),
            meal(id: "meal-3")
        ]

        XCTAssertEqual(state.selectedMeals(from: templates).map(\.id), ["meal-2"])
    }

    func testRestoreDoesNotRewriteSnapshotDuringInit() throws {
        let state = LocalAppState(defaults: defaults)
        state.selectedDayOverride = .saturday
        state.setProgress = [SetProgress(exerciseID: "split-squat", completedSets: [0, 1])]
        state.selectedMealIDs = ["meal-1"]
        state.checkedGroceryItemIDs = ["spinach"]
        state.quickProteinAdds = [30]

        let originalData = try XCTUnwrap(defaults.data(forKey: storageKey))
        let recordingDefaults = try XCTUnwrap(RecordingUserDefaults(suiteName: suiteName))
        recordingDefaults.removeAllRecordedSets()

        _ = LocalAppState(defaults: recordingDefaults)

        XCTAssertEqual(recordingDefaults.recordedSetCount(forKey: storageKey), 0)
        XCTAssertEqual(recordingDefaults.data(forKey: storageKey), originalData)
    }

    private func meal(id: String) -> MealTemplate {
        MealTemplate(
            id: id,
            kind: .lunch,
            name: id,
            detail: "Test meal",
            calories: 500,
            proteinGrams: 40,
            fatGrams: 15,
            carbsGrams: 50,
            ingredients: []
        )
    }
}

private final class RecordingUserDefaults: UserDefaults {
    private var setCounts: [String: Int] = [:]

    override func set(_ value: Any?, forKey defaultName: String) {
        setCounts[defaultName, default: 0] += 1
        super.set(value, forKey: defaultName)
    }

    func recordedSetCount(forKey key: String) -> Int {
        setCounts[key, default: 0]
    }

    func removeAllRecordedSets() {
        setCounts.removeAll()
    }
}
