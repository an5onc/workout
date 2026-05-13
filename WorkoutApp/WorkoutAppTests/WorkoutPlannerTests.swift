import XCTest
@testable import WorkoutApp

final class WorkoutPlannerTests: XCTestCase {
    func testWeekdayLookupUsesManualOverrideWhenPresent() {
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let workout = planner.workout(for: .monday, override: .saturday)
        XCTAssertEqual(workout?.name, "Lower C")
    }

    func testWeekdayLookupFallsBackToCurrentDay() {
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let workout = planner.workout(for: .monday, override: nil)
        XCTAssertEqual(workout?.name, "Lower A")
    }

    func testDateLookupUsesDateWeekday() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let monday = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 11, hour: 12).date!
        let saturday = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 16, hour: 12).date!
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)

        XCTAssertEqual(planner.workout(for: monday, calendar: calendar)?.name, "Lower A")
        XCTAssertEqual(planner.workout(for: saturday, calendar: calendar)?.name, "Lower C")
    }

    func testActiveExerciseAdvancesAfterCompletedSets() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let completed = SetProgress(exerciseID: "barbell-hip-thrust", completedSets: [0, 1, 2, 3])
        let active = planner.activeExercise(in: lowerA, progress: [completed])
        XCTAssertEqual(active?.id, "heel-elevated-goblet-squat")
    }

    func testActiveExerciseReturnsNilForRestDay() throws {
        let restDay = try XCTUnwrap(ProgramSeed.workout(for: .thursday))
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let active = planner.activeExercise(in: restDay, progress: [])
        XCTAssertNil(active)
    }

    func testActiveExerciseKeepsIncompleteFirstExerciseActive() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let completed = SetProgress(exerciseID: "barbell-hip-thrust", completedSets: [0, 1])
        let active = planner.activeExercise(in: lowerA, progress: [completed])
        XCTAssertEqual(active?.id, "barbell-hip-thrust")
    }

    func testActiveExerciseReturnsNilWhenAllExercisesComplete() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let progress = lowerA.exercises.map { exercise in
            SetProgress(exerciseID: exercise.id, completedSets: Set(0..<exercise.sets))
        }
        let active = planner.activeExercise(in: lowerA, progress: progress)
        XCTAssertNil(active)
    }

    func testOutOfRangeCompletedSetIndexesDoNotAdvance() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let completed = SetProgress(exerciseID: "barbell-hip-thrust", completedSets: [99, 100, 101, 102])
        let active = planner.activeExercise(in: lowerA, progress: [completed])
        XCTAssertEqual(active?.id, "barbell-hip-thrust")
    }

    func testProgressionSuggestionIncreasesAfterTopRangeCompleted() {
        let exercise = Exercise(
            id: "hip-thrust",
            name: "Hip Thrust",
            sets: 3,
            repRange: "8-10",
            rest: "90s",
            cue: "Drive through heels.",
            formCues: [],
            mistakes: [],
            feel: "Glutes",
            demoURL: nil
        )
        let progress = SetProgress(
            exerciseID: "hip-thrust",
            completedSets: [0, 1, 2],
            setEntries: [
                SetEntry(setIndex: 0, weightText: "135", repsText: "10", isCompleted: true),
                SetEntry(setIndex: 1, weightText: "135", repsText: "10", isCompleted: true),
                SetEntry(setIndex: 2, weightText: "135", repsText: "10", isCompleted: true)
            ]
        )

        XCTAssertEqual(WorkoutProgressAdvisor.suggestion(for: exercise, progress: progress), "Next time: try 140 lb.")
    }

    func testProgressionSuggestionRepeatsWhenTargetNotCleared() {
        let exercise = Exercise(
            id: "hip-thrust",
            name: "Hip Thrust",
            sets: 3,
            repRange: "8-10",
            rest: "90s",
            cue: "Drive through heels.",
            formCues: [],
            mistakes: [],
            feel: "Glutes",
            demoURL: nil
        )
        let progress = SetProgress(
            exerciseID: "hip-thrust",
            completedSets: [0, 1, 2],
            setEntries: [
                SetEntry(setIndex: 0, weightText: "135", repsText: "10", isCompleted: true),
                SetEntry(setIndex: 1, weightText: "135", repsText: "9", isCompleted: true),
                SetEntry(setIndex: 2, weightText: "135", repsText: "8", isCompleted: true)
            ]
        )

        XCTAssertEqual(WorkoutProgressAdvisor.suggestion(for: exercise, progress: progress), "Next time: repeat 135 lb.")
    }

    func testWorkoutSummaryCountsSetsAndVolume() throws {
        let workout = WorkoutDay(
            id: .monday,
            name: "Lower A",
            focus: "Lower",
            subtitle: "Test",
            isRestDay: false,
            exercises: [
                Exercise(id: "hip-thrust", name: "Hip Thrust", sets: 2, repRange: "8-10", rest: "90s", cue: "Drive.", formCues: [], mistakes: [], feel: "Glutes", demoURL: nil),
                Exercise(id: "lunge", name: "Lunge", sets: 2, repRange: "10", rest: "60s", cue: "Step.", formCues: [], mistakes: [], feel: "Legs", demoURL: nil)
            ]
        )
        let log = WorkoutLog(
            dateKey: "2026-05-11",
            setProgress: [
                SetProgress(exerciseID: "hip-thrust", completedSets: [0, 1], setEntries: [
                    SetEntry(setIndex: 0, weightText: "135", repsText: "10", isCompleted: true),
                    SetEntry(setIndex: 1, weightText: "135", repsText: "8", isCompleted: true)
                ]),
                SetProgress(exerciseID: "lunge", completedSets: [0], setEntries: [
                    SetEntry(setIndex: 0, weightText: "25", repsText: "10", isCompleted: true)
                ])
            ]
        )

        let summary = WorkoutPlanner.summary(for: workout, log: log)

        XCTAssertEqual(summary.completedSets, 3)
        XCTAssertEqual(summary.totalSets, 4)
        XCTAssertEqual(summary.remainingSets, 1)
        XCTAssertEqual(summary.totalVolume, 2680)
        XCTAssertFalse(summary.isFinished)
    }
}
