import XCTest
@testable import WorkoutApp

final class ProgressMetricsCalculatorTests: XCTestCase {
    func testCompositionTrendUsesEarliestAndLatestNumericCheckIns() {
        let checkIns = [
            WeeklyCheckIn(dateKey: "2026-05-18", bodyWeightText: "180.5", waistText: "34.0"),
            WeeklyCheckIn(dateKey: "2026-05-11", bodyWeightText: "183", waistText: "35"),
            WeeklyCheckIn(dateKey: "2026-05-25", bodyWeightText: "bad", waistText: "33.5")
        ]

        XCTAssertEqual(ProgressMetricsCalculator.change(in: checkIns, value: \.bodyWeightText), -2.5)
        XCTAssertEqual(ProgressMetricsCalculator.change(in: checkIns, value: \.waistText), -1.5)
    }

    func testWeeklyAdherenceAndCardioCompletionUseSelectedProgramLogs() throws {
        let program = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let referenceDate = date(year: 2026, month: 5, day: 30)
        let logs = [
            WorkoutLog(dateKey: "2026-05-25", programID: program.id, finishedAt: referenceDate),
            WorkoutLog(dateKey: "2026-05-26", programID: program.id, finishedAt: referenceDate),
            WorkoutLog(dateKey: "2026-05-30", programID: program.id, finishedAt: referenceDate),
            WorkoutLog(dateKey: "2026-05-30", programID: ProgramSeed.defaultProgramID, finishedAt: referenceDate)
        ]

        let adherence = ProgressMetricsCalculator.weeklyAdherence(
            program: program,
            workoutLogs: logs,
            referenceDate: referenceDate,
            calendar: calendar
        )

        XCTAssertEqual(adherence.completedTrainingDays, 3)
        XCTAssertEqual(adherence.plannedTrainingDays, 6)
        XCTAssertEqual(adherence.completedCardioDays, 3)
        XCTAssertEqual(adherence.plannedCardioDays, 5)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day, hour: 12).date!
    }
}
