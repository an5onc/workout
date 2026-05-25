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

    func testModifiedPushupsCannotAssignAdvancedLevel() {
        let profile = profile(limitations: "")

        let kneePushups = assessment(pushUps: 45, pushUpVariation: .knee, steps: 120, mileSeconds: 540)
        let inclinePushups = assessment(pushUps: 45, pushUpVariation: .incline, steps: 120, mileSeconds: 540)

        XCTAssertEqual(PersonalizationCalculator.level(for: profile, assessment: kneePushups), .moderate)
        XCTAssertEqual(PersonalizationCalculator.level(for: profile, assessment: inclinePushups), .moderate)
    }

    func testHighDifficultyDownshiftsModerateAssessment() {
        let profile = profile(limitations: "")
        let assessment = assessment(pushUps: 20, steps: 92, mileSeconds: 820, stepDifficulty: 9, mileDifficulty: 8)

        XCTAssertEqual(PersonalizationCalculator.level(for: profile, assessment: assessment), .beginner)
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

    func testWeakAssessmentHandpicksPushAndAerobicBaseExercises() throws {
        let base = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let profile = profile(weight: 220, limitations: "")
        let program = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(pushUps: 4, steps: 52, mileSeconds: 1_120, stepDifficulty: 8, mileDifficulty: 8),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )

        let exerciseNames = program.generatedProgram.weeklySchedule.flatMap(\.exercises).map(\.name)

        XCTAssertTrue(exerciseNames.contains("Incline Push-Up Practice"))
        XCTAssertTrue(exerciseNames.contains("Treadmill Walk Intervals"))
        XCTAssertTrue(program.generatedProgram.weeklyStructure.contains("Push-strength base: incline push-up practice"))
        XCTAssertTrue(program.generatedProgram.weeklyStructure.contains("Aerobic base: repeatable treadmill intervals"))
    }

    func testStrengthPlanAlsoUsesAdaptiveExerciseTags() throws {
        let base = try XCTUnwrap(ProgramSeed.program(id: ProgramSeed.defaultProgramID))
        let profile = profile(weight: 180, limitations: "Knee soreness")
        let program = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(pushUps: 4, steps: 72, mileSeconds: 980, stepDifficulty: 9, mileDifficulty: 8),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )

        let exerciseNames = program.generatedProgram.weeklySchedule.flatMap(\.exercises).map(\.name)

        XCTAssertTrue(exerciseNames.contains("Incline Push-Up Practice"))
        XCTAssertTrue(exerciseNames.contains("Supported Split Squat"))
        XCTAssertTrue(program.generatedProgram.weeklyStructure.contains("Joint-friendly loading: stable lower-impact exercise choices"))
    }

    func testAdaptiveExplanationsDescribeExerciseChoicesForUsers() {
        let profile = profile(weight: 220, limitations: "Knee soreness")
        let explanations = PersonalizationCalculator.adaptiveExplanations(
            for: profile,
            assessment: assessment(pushUps: 4, steps: 52, mileSeconds: 1_120, stepDifficulty: 9, mileDifficulty: 8)
        )

        XCTAssertTrue(explanations.contains("Push-up result was low, so the plan uses incline push-up practice to build clean pressing strength."))
        XCTAssertTrue(explanations.contains("Step test or mile result showed aerobic base needs work, so conditioning is built around repeatable treadmill intervals."))
        XCTAssertTrue(explanations.contains("Difficulty rating or limitations were high, so lower-body choices favor stable, joint-friendly movements."))
    }

    func testAdvancedAssessmentProgressesFutureExercises() throws {
        let base = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let profile = profile(weight: 170, limitations: "")
        let program = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(phase: .week6, dateKey: "2026-06-12", pushUps: 42, steps: 122, mileSeconds: 540),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )

        let exerciseNames = program.generatedProgram.weeklySchedule.flatMap(\.exercises).map(\.name)

        XCTAssertTrue(exerciseNames.contains("Push-Up Progression"))
        XCTAssertTrue(exerciseNames.contains("Treadmill Run/Walk Intervals"))
        XCTAssertTrue(program.generatedProgram.weeklyStructure.contains("Advanced progression: harder push and interval work"))
    }

    func testAdaptiveExerciseDemoLinksAreCuratedNotSearches() throws {
        let base = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let profile = profile(weight: 170, limitations: "")
        let beginner = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(pushUps: 4, steps: 52, mileSeconds: 1_120),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )
        let advanced = PersonalizationCalculator.personalizedProgram(
            base: base,
            profile: profile,
            assessment: assessment(pushUps: 42, steps: 122, mileSeconds: 540),
            startDate: date(year: 2026, month: 5, day: 1),
            calendar: calendar
        )

        let urls = (beginner.generatedProgram.weeklySchedule + advanced.generatedProgram.weeklySchedule)
            .flatMap(\.exercises)
            .compactMap(\.demoURL)

        XCTAssertTrue(urls.contains { $0.absoluteString.contains("incline-push-up") })
        XCTAssertTrue(urls.contains { $0.absoluteString.contains("treadmill") })
        XCTAssertTrue(urls.allSatisfy { $0.host == "musclewiki.com" })
        XCTAssertFalse(urls.contains { $0.absoluteString.contains("youtube.com/results") })
        XCTAssertFalse(urls.contains { $0.absoluteString.contains("search_query") })
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
        pushUpVariation: PushUpVariation = .standard,
        steps: Int,
        mileSeconds: Int,
        stepDifficulty: Int = 6,
        mileDifficulty: Int = 7
    ) -> FitnessAssessment {
        FitnessAssessment(
            dateKey: dateKey,
            phase: phase,
            pushUpReps: pushUps,
            pushUpVariation: pushUpVariation,
            stepTestDurationSeconds: 180,
            stepCount: steps,
            recoveryHeartRate: 120,
            stepTestDifficulty: stepDifficulty,
            oneMileTimeSeconds: mileSeconds,
            oneMileStyle: .walkRun,
            oneMileDifficulty: mileDifficulty,
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
