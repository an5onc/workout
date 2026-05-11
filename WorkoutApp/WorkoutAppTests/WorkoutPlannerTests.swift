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
}
