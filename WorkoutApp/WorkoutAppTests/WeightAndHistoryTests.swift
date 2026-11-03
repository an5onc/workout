import XCTest
@testable import WorkoutApp

final class WeightAndHistoryTests: XCTestCase {
    func testConvertsBetweenPoundsAndKilograms() {
        XCTAssertEqual(WeightUnit.kg.convert(100, to: .lb), 220.462, accuracy: 0.001)
        XCTAssertEqual(WeightUnit.lb.convert(135, to: .kg), 61.235, accuracy: 0.001)
        XCTAssertEqual(WeightUnit.lb.convert(135, to: .lb), 135)
    }

    func testFormatterRoundsToOneDecimalAndDropsTrailingZero() {
        XCTAssertEqual(WeightFormatter.string(135), "135")
        XCTAssertEqual(WeightFormatter.string(61.2349), "61.2")
        XCTAssertEqual(WeightFormatter.string(99.96), "100")
    }

    func testLegacyEntryWithoutUnitIsPounds() throws {
        let json = #"{"setIndex":0,"weightText":"135","repsText":"10","isCompleted":true}"#
        let entry = try JSONDecoder().decode(SetEntry.self, from: Data(json.utf8))

        XCTAssertNil(entry.unit)
        XCTAssertEqual(entry.weightUnit, .lb)
        XCTAssertEqual(entry.displayWeightText(in: .kg), "61.2")
        XCTAssertEqual(entry.displayWeightText(in: .lb), "135")
    }

    func testBestLiftsCompareAcrossUnits() {
        let logs = [
            log("2026-05-11", "hip-thrust", SetEntry(setIndex: 0, weightText: "135", repsText: "10", isCompleted: true, unit: .lb)),
            log("2026-05-18", "hip-thrust", SetEntry(setIndex: 0, weightText: "70", repsText: "6", isCompleted: true, unit: .kg))
        ]

        let inPounds = WorkoutHistory.bestLifts(logs: logs, programID: "p", unit: .lb)
        let inKilograms = WorkoutHistory.bestLifts(logs: logs, programID: "p", unit: .kg)

        XCTAssertEqual(inPounds.count, 1)
        XCTAssertEqual(inPounds[0].reps, 6, "70 kg (154 lb) beats 135 lb")
        XCTAssertEqual(inPounds[0].weight, 154.32, accuracy: 0.01)
        XCTAssertEqual(inKilograms[0].weight, 70, accuracy: 0.001)
    }

    func testBestLiftsIgnoresIncompleteSetsAndOtherPrograms() {
        let logs = [
            log("2026-05-11", "hip-thrust", SetEntry(setIndex: 0, weightText: "200", repsText: "5", isCompleted: false)),
            WorkoutLog(dateKey: "2026-05-12", programID: "other", setProgress: [
                SetProgress(exerciseID: "hip-thrust", completedSets: [0], setEntries: [SetEntry(setIndex: 0, weightText: "300", repsText: "5", isCompleted: true)])
            ]),
            log("2026-05-13", "hip-thrust", SetEntry(setIndex: 0, weightText: "135", repsText: "8", isCompleted: true))
        ]

        let records = WorkoutHistory.bestLifts(logs: logs, programID: "p", unit: .lb)

        XCTAssertEqual(records.first?.weight, 135)
    }

    func testSessionSummaryConvertsMixedUnits() {
        let progress = SetProgress(exerciseID: "x", completedSets: [0, 1], setEntries: [
            SetEntry(setIndex: 0, weightText: "60", repsText: "10", isCompleted: true, unit: .kg),
            SetEntry(setIndex: 1, weightText: "60", repsText: "9", isCompleted: true, unit: .kg)
        ])

        XCTAssertEqual(WorkoutHistory.sessionSummary(for: progress, unit: .kg), "60 kg x 10, 9")
        XCTAssertEqual(WorkoutHistory.sessionSummary(for: progress, unit: .lb), "132.3 lb x 10, 9")
    }

    func testWorkoutSummaryVolumeUsesRequestedUnit() {
        let workout = WorkoutDay(id: .monday, name: "A", focus: "Lower", subtitle: "", isRestDay: false, exercises: [
            Exercise(id: "x", name: "X", sets: 1, repRange: "10", rest: "90s", cue: "", formCues: [], mistakes: [], feel: "", demoURL: nil)
        ])
        let log = WorkoutLog(dateKey: "2026-05-11", setProgress: [
            SetProgress(exerciseID: "x", completedSets: [0], setEntries: [
                SetEntry(setIndex: 0, weightText: "100", repsText: "10", isCompleted: true, unit: .lb)
            ])
        ])

        XCTAssertEqual(WorkoutPlanner.summary(for: workout, log: log, unit: .lb).totalVolume, 1000)
        XCTAssertEqual(WorkoutPlanner.summary(for: workout, log: log, unit: .kg).totalVolume, 453.59, accuracy: 0.01)
    }

    func testProgressionSuggestionUsesKilogramIncrements() {
        let exercise = Exercise(id: "x", name: "X", sets: 2, repRange: "8-10", rest: "90s", cue: "", formCues: [], mistakes: [], feel: "", demoURL: nil)
        let progress = SetProgress(exerciseID: "x", completedSets: [0, 1], setEntries: [
            SetEntry(setIndex: 0, weightText: "60", repsText: "10", isCompleted: true, unit: .kg),
            SetEntry(setIndex: 1, weightText: "60", repsText: "10", isCompleted: true, unit: .kg)
        ])

        XCTAssertEqual(WorkoutProgressAdvisor.suggestion(for: exercise, progress: progress, unit: .kg), "Next time: try 62.5 kg.")
    }

    private func log(_ dateKey: String, _ exerciseID: String, _ entry: SetEntry) -> WorkoutLog {
        WorkoutLog(dateKey: dateKey, programID: "p", setProgress: [
            SetProgress(exerciseID: exerciseID, completedSets: entry.isCompleted ? [entry.setIndex] : [], setEntries: [entry])
        ])
    }
}
