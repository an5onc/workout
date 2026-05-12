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
        state.foodLogs = [
            FoodLog(dateKey: "2026-05-11", checkedMealIDs: ["protein-oatmeal"], quickProteinAdds: [10, 25])
        ]

        let restored = LocalAppState(defaults: defaults)

        XCTAssertEqual(restored.selectedDayOverride, .friday)
        XCTAssertEqual(restored.setProgress, state.setProgress)
        XCTAssertEqual(restored.selectedMealIDs, ["breakfast-a", "dinner-b"])
        XCTAssertEqual(restored.checkedGroceryItemIDs, ["eggs", "rice"])
        XCTAssertEqual(restored.foodLogs, state.foodLogs)
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

    func testSetEntryWeightRepsAndCompletionPersistByDate() {
        let state = LocalAppState(defaults: defaults)
        let date = date(year: 2026, month: 5, day: 11)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: date)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: date)

        let restored = LocalAppState(defaults: defaults)
        let entry = restored.setEntry(exerciseID: "hip-thrust", setIndex: 0)

        XCTAssertEqual(entry.weightText, "135")
        XCTAssertEqual(entry.repsText, "10")
        XCTAssertTrue(entry.isCompleted)
        XCTAssertEqual(restored.workoutLog(for: date).setProgress.first?.setEntries.first, entry)
    }

    func testSelectedSubstitutionPersistsByDate() {
        let state = LocalAppState(defaults: defaults)
        let monday = date(year: 2026, month: 5, day: 11)
        let tuesday = date(year: 2026, month: 5, day: 12)

        state.selectSubstitution(exerciseID: "barbell-hip-thrust", substitutionID: "smith-machine-hip-thrust", date: monday)

        let restored = LocalAppState(defaults: defaults)

        XCTAssertEqual(restored.selectedSubstitutionID(exerciseID: "barbell-hip-thrust", date: monday), "smith-machine-hip-thrust")
        XCTAssertNil(restored.selectedSubstitutionID(exerciseID: "barbell-hip-thrust", date: tuesday))
    }

    func testFinishingWorkoutPersistsByDate() {
        let state = LocalAppState(defaults: defaults)
        let monday = date(year: 2026, month: 5, day: 11)
        let tuesday = date(year: 2026, month: 5, day: 12)

        state.finishWorkout(date: monday)

        let restored = LocalAppState(defaults: defaults)

        XCTAssertTrue(restored.isWorkoutFinished(date: monday))
        XCTAssertFalse(restored.isWorkoutFinished(date: tuesday))
    }

    func testLastPerformanceSummaryUsesPreviousDate() {
        let state = LocalAppState(defaults: defaults)
        let today = date(year: 2026, month: 5, day: 18)
        let lastWeek = date(year: 2026, month: 5, day: 11)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: lastWeek)
        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 1, weightText: "135", repsText: "9", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 1, date: lastWeek)
        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "140", repsText: "8", date: today)

        XCTAssertEqual(state.lastPerformanceSummary(exerciseID: "hip-thrust", before: today), "135 lb x 10, 9")
    }

    func testWeeklyCheckInPersists() {
        let state = LocalAppState(defaults: defaults)
        let date = date(year: 2026, month: 5, day: 17)

        state.updateWeeklyCheckIn(date: date, bodyWeightText: "142.4", waistText: "28", hipsText: "39", energy: 4, soreness: 2, notes: "Good week")

        let restored = LocalAppState(defaults: defaults)
        let checkIn = restored.weeklyCheckIn(for: date)

        XCTAssertEqual(checkIn.bodyWeightText, "142.4")
        XCTAssertEqual(checkIn.waistText, "28")
        XCTAssertEqual(checkIn.hipsText, "39")
        XCTAssertEqual(checkIn.energy, 4)
        XCTAssertEqual(checkIn.soreness, 2)
        XCTAssertEqual(checkIn.notes, "Good week")
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

    func testFoodLogMealSelectionIsSeparateFromGroceryMealSelection() {
        let state = LocalAppState(defaults: defaults)
        let date = date(year: 2026, month: 5, day: 11)

        state.selectedMealIDs = ["grocery-meal"]
        state.toggleFoodMeal("food-meal", on: true, date: date)

        XCTAssertEqual(state.selectedMealIDs, ["grocery-meal"])
        XCTAssertEqual(state.foodLog(for: date).checkedMealIDs, ["food-meal"])
    }

    func testFoodQuickProteinAddsAreScopedByDate() {
        let state = LocalAppState(defaults: defaults)
        let today = date(year: 2026, month: 5, day: 11)
        let yesterday = date(year: 2026, month: 5, day: 10)

        state.addQuickProtein(25, date: yesterday)
        state.addQuickProtein(10, date: today)
        state.addQuickProtein(20, date: today)

        XCTAssertEqual(state.foodLog(for: yesterday).quickProteinAdds, [25])
        XCTAssertEqual(state.foodLog(for: today).quickProteinAdds, [10, 20])

        state.removeLastQuickProteinAdd(date: today)

        XCTAssertEqual(state.foodLog(for: yesterday).quickProteinAdds, [25])
        XCTAssertEqual(state.foodLog(for: today).quickProteinAdds, [10])

        state.clearQuickProteinAdds(date: today)

        XCTAssertEqual(state.foodLog(for: yesterday).quickProteinAdds, [25])
        XCTAssertEqual(state.foodLog(for: today).quickProteinAdds, [])
    }

    func testFoodLogsPersistByDateWithoutBreakingGroceryState() {
        let state = LocalAppState(defaults: defaults)
        let today = date(year: 2026, month: 5, day: 11)
        let yesterday = date(year: 2026, month: 5, day: 10)
        state.selectedMealIDs = ["grocery-meal"]
        state.checkedGroceryItemIDs = ["rice"]
        state.toggleFoodMeal("today-meal", on: true, date: today)
        state.addQuickProtein(20, date: today)
        state.addQuickProtein(30, date: yesterday)

        let restored = LocalAppState(defaults: defaults)

        XCTAssertEqual(restored.selectedMealIDs, ["grocery-meal"])
        XCTAssertEqual(restored.checkedGroceryItemIDs, ["rice"])
        XCTAssertEqual(restored.foodLog(for: today).checkedMealIDs, ["today-meal"])
        XCTAssertEqual(restored.foodLog(for: today).quickProteinAdds, [20])
        XCTAssertEqual(restored.foodLog(for: yesterday).quickProteinAdds, [30])
    }

    func testSavedSnapshotDoesNotRoundTripLegacyTopLevelQuickProteinAdds() throws {
        let state = LocalAppState(defaults: defaults)
        state.selectedDayOverride = .monday

        let data = try XCTUnwrap(defaults.data(forKey: storageKey))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["quickProteinAdds"])
    }

    func testRestoreDoesNotRewriteSnapshotDuringInit() throws {
        let state = LocalAppState(defaults: defaults)
        state.selectedDayOverride = .saturday
        state.setProgress = [SetProgress(exerciseID: "split-squat", completedSets: [0, 1])]
        state.selectedMealIDs = ["meal-1"]
        state.checkedGroceryItemIDs = ["spinach"]
        state.addQuickProtein(30, date: date(year: 2026, month: 5, day: 11))

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

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: Calendar.current, year: year, month: month, day: day, hour: 12).date!
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
