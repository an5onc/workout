import XCTest
@testable import WorkoutApp

final class PersonalizationCalculatorTests: XCTestCase {
    func testAssessmentLevelUsesPushupsStepTestAndMileTime() {
        let profile = profile(limitations: "")

        XCTAssertEqual(PersonalizationCalculator.level(for: profile, assessment: assessment(pushUps: 5, steps: 55, mileSeconds: 1_050)), .beginner)
        XCTAssertEqual(PersonalizationCalculator.level(for: profile, assessment: assessment(pushUps: 18, steps: 85, mileSeconds: 760)), .moderate)
        XCTAssertEqual(PersonalizationCalculator.level(for: profile, assessment: assessment(pushUps: 38, steps: 118, mileSeconds: 560)), .advanced)
    }

    func testLimitationsDownshiftAdvancedAssessment() {
        let profile = profile(limitations: "knee pain")
        let level = PersonalizationCalculator.level(for: profile, assessment: assessment(pushUps: 40, steps: 120, mileSeconds: 540))

        XCTAssertEqual(level, .moderate)
    }

    func testGeneratedPlanVolumeAndNutritionChangeByLevel() throws {
        let base = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let profile = profile(weight: 200, limitations: "")
        let beginner = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(pushUps: 5, steps: 55, mileSeconds: 1_050),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )
        let advanced = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(pushUps: 38, steps: 118, mileSeconds: 560),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )

        let baseSets = try XCTUnwrap(base.weeklySchedule.first { $0.id == .monday }?.exercises.first?.sets)
        let beginnerSets = try XCTUnwrap(beginner.generatedProgram.weeklySchedule.first { $0.id == .monday }?.exercises.first?.sets)
        let advancedSets = try XCTUnwrap(advanced.generatedProgram.weeklySchedule.first { $0.id == .monday }?.exercises.first?.sets)

        XCTAssertEqual(beginner.assignedLevel, .beginner)
        XCTAssertEqual(advanced.assignedLevel, .advanced)
        XCTAssertLessThan(beginnerSets, baseSets)
        XCTAssertGreaterThan(advancedSets, baseSets)
        XCTAssertEqual(advanced.generatedProgram.nutritionTargets.proteinGrams, 160)
    }

    func testRetestDueDatesAtWeekSixAndWeekTwelve() throws {
        let base = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let baseline = assessment(phase: .baseline, dateKey: "2026-05-01", pushUps: 18, steps: 85, mileSeconds: 760)
        let program = PersonalizedProgram(
            baseProgramID: base.id,
            assignedLevel: .moderate,
            generatedProgram: base,
            baselineAssessmentID: baseline.id,
            latestAssessmentID: baseline.id,
            startDateKey: "2026-05-01"
        )

        XCTAssertNil(PersonalizationCalculator.nextRetestPhase(program: program, assessments: [baseline], on: date(year: 2026, month: 6, day: 11), calendar: calendar))
        XCTAssertEqual(PersonalizationCalculator.nextRetestPhase(program: program, assessments: [baseline], on: date(year: 2026, month: 6, day: 12), calendar: calendar), .week6)

        let week6 = assessment(phase: .week6, dateKey: "2026-06-12", pushUps: 24, steps: 95, mileSeconds: 700)
        XCTAssertNil(PersonalizationCalculator.nextRetestPhase(program: program, assessments: [baseline, week6], on: date(year: 2026, month: 7, day: 23), calendar: calendar))
        XCTAssertEqual(PersonalizationCalculator.nextRetestPhase(program: program, assessments: [baseline, week6], on: date(year: 2026, month: 7, day: 24), calendar: calendar), .week12)
        XCTAssertTrue(PersonalizationCalculator.isRetestDue(program: program, assessments: [baseline, week6], on: date(year: 2026, month: 7, day: 24), calendar: calendar))
    }

    private func profile(weight: Int = 180, limitations: String) -> UserProfile {
        UserProfile(
            age: 34,
            heightInches: 66,
            weightPounds: weight,
            experienceLevel: "Some training",
            availableWorkoutDaysPerWeek: 4,
            limitations: limitations
        )
    }

    private func assessment(
        phase: AssessmentPhase = .baseline,
        dateKey: String = "2026-05-01",
        pushUps: Int,
        steps: Int,
        mileSeconds: Int
    ) -> FitnessAssessment {
        FitnessAssessment(
            dateKey: dateKey,
            phase: phase,
            pushUpReps: pushUps,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: steps,
            recoveryHeartRate: 120,
            stepTestDifficulty: 6,
            oneMileTimeSeconds: mileSeconds,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 7,
            computedLevel: .beginner
        )
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
