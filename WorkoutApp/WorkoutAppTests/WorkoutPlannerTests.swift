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
}
