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
        state.selectedProgramID = "weight-loss-foundation"
        state.setProgress = [
            SetProgress(exerciseID: "hip-thrust", completedSets: [0, 2], weightText: "135", repsText: "10", rpeText: "8")
        ]
        state.selectedMealIDs = ["breakfast-a", "dinner-b"]
        state.checkedGroceryItemIDs = ["eggs", "rice"]
        state.foodLogs = [
            FoodLog(dateKey: "2026-05-11", checkedMealIDs: ["protein-oatmeal"], quickProteinAdds: [10, 25])
        ]

        let restored = LocalAppState(defaults: defaults)

        XCTAssertEqual(restored.selectedProgramID, "weight-loss-foundation")
        XCTAssertEqual(restored.selectedProgram.id, "weight-loss-foundation")
        XCTAssertEqual(restored.setProgress, state.setProgress)
        XCTAssertEqual(restored.selectedMealIDs, ["breakfast-a", "dinner-b"])
        XCTAssertEqual(restored.checkedGroceryItemIDs, ["eggs", "rice"])
        XCTAssertEqual(restored.foodLogs, state.foodLogs)
    }

    func testSelectedProgramDefaultsAndFallsBackForInvalidID() {
        let state = LocalAppState(defaults: defaults)

        XCTAssertEqual(state.selectedProgramID, ProgramSeed.defaultProgramID)
        XCTAssertEqual(state.selectedProgram.id, ProgramSeed.defaultProgramID)

        state.selectedProgramID = "missing-program"

        XCTAssertEqual(state.selectedProgram.id, ProgramSeed.defaultProgramID)
    }

    func testSelectingDifferentProgramClearsGrocerySessionState() {
        let state = LocalAppState(defaults: defaults)
        state.selectedMealIDs = ["protein-oatmeal"]
        state.checkedGroceryItemIDs = ["rolled-oats"]

        state.selectProgram(id: "weight-loss-foundation")

        XCTAssertEqual(state.selectedProgramID, "weight-loss-foundation")
        XCTAssertTrue(state.selectedMealIDs.isEmpty)
        XCTAssertTrue(state.checkedGroceryItemIDs.isEmpty)
    }

    func testSelectingCurrentProgramKeepsGrocerySessionState() {
        let state = LocalAppState(defaults: defaults)
        state.selectedMealIDs = ["protein-oatmeal"]
        state.checkedGroceryItemIDs = ["rolled-oats"]

        state.selectProgram(id: ProgramSeed.defaultProgramID)

        XCTAssertEqual(state.selectedMealIDs, ["protein-oatmeal"])
        XCTAssertEqual(state.checkedGroceryItemIDs, ["rolled-oats"])
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

    func testWorkoutLogsAreScopedBySelectedProgram() {
        let state = LocalAppState(defaults: defaults)
        let date = date(year: 2026, month: 5, day: 11)

        state.toggleSet(exerciseID: "barbell-hip-thrust", setIndex: 0, date: date)
        state.selectProgram(id: "weight-loss-foundation")
        state.toggleSet(exerciseID: "wl-goblet-squat", setIndex: 0, date: date)

        XCTAssertEqual(state.workoutLogs.count, 2)
        XCTAssertEqual(state.workoutLog(for: date).programID, "weight-loss-foundation")
        XCTAssertEqual(state.workoutLog(for: date).setProgress.first?.exerciseID, "wl-goblet-squat")

        state.selectProgram(id: ProgramSeed.defaultProgramID)

        XCTAssertEqual(state.workoutLog(for: date).programID, ProgramSeed.defaultProgramID)
        XCTAssertEqual(state.workoutLog(for: date).setProgress.first?.exerciseID, "barbell-hip-thrust")
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

    func testFutureSubstitutionDoesNotAffectToday() {
        let state = LocalAppState(defaults: defaults)
        let today = date(year: 2026, month: 5, day: 12)
        let future = date(year: 2026, month: 5, day: 13)

        state.selectSubstitution(exerciseID: "db-bench-press", substitutionID: "smith-machine-bench", date: future)

        XCTAssertNil(state.selectedSubstitutionID(exerciseID: "db-bench-press", date: today))
        XCTAssertEqual(state.selectedSubstitutionID(exerciseID: "db-bench-press", date: future), "smith-machine-bench")
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

    func testNewDayStartsWithEmptySetsAndLeavesPreviousLogIntact() {
        let state = LocalAppState(defaults: defaults)
        let lastMonday = date(year: 2026, month: 5, day: 11)
        let nextMonday = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "barbell-hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastMonday)
        state.toggleSet(exerciseID: "barbell-hip-thrust", setIndex: 0, date: lastMonday)

        let restored = LocalAppState(defaults: defaults)
        restored.prepareDay(nextMonday)

        XCTAssertEqual(restored.progress(for: "barbell-hip-thrust").completedSets, [])
        XCTAssertEqual(restored.setEntry(exerciseID: "barbell-hip-thrust", setIndex: 0).weightText, "")
        XCTAssertEqual(restored.workoutLog(for: lastMonday).setProgress.first?.setEntries.first?.weightText, "135")
    }

    func testFirstTapOnNewDayDoesNotCopyPreviousDaySets() {
        let state = LocalAppState(defaults: defaults)
        let lastMonday = date(year: 2026, month: 5, day: 11)
        let nextMonday = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "barbell-hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastMonday)
        state.toggleSet(exerciseID: "barbell-hip-thrust", setIndex: 0, date: lastMonday)
        state.toggleSet(exerciseID: "barbell-hip-thrust", setIndex: 1, date: lastMonday)

        state.updateSetEntry(exerciseID: "romanian-deadlift", setIndex: 0, weightText: "95", repsText: "8", date: nextMonday)

        let todayLog = state.workoutLog(for: nextMonday)
        XCTAssertEqual(todayLog.setProgress.map(\.exerciseID), ["romanian-deadlift"])
        XCTAssertEqual(state.workoutLog(for: lastMonday).setProgress.first?.completedSets, [0, 1])
    }

    func testSameDayRelaunchKeepsTodaysSets() {
        let state = LocalAppState(defaults: defaults)
        let monday = date(year: 2026, month: 5, day: 11)
        state.toggleSet(exerciseID: "barbell-hip-thrust", setIndex: 0, date: monday)

        let restored = LocalAppState(defaults: defaults)
        restored.prepareDay(monday)

        XCTAssertEqual(restored.progress(for: "barbell-hip-thrust").completedSets, [0])
    }

    func testDayOverrideAppliesOnlyToItsDate() {
        let state = LocalAppState(defaults: defaults)
        let tuesday = date(year: 2026, month: 5, day: 12)
        let wednesday = date(year: 2026, month: 5, day: 13)

        state.setWorkoutDayOverride(.monday, date: tuesday)

        let restored = LocalAppState(defaults: defaults)
        XCTAssertEqual(restored.workoutDayOverride(on: tuesday), .monday)
        XCTAssertEqual(restored.scheduledWorkout(on: tuesday)?.id, .monday)
        XCTAssertNil(restored.workoutDayOverride(on: wednesday))
        XCTAssertEqual(restored.scheduledWorkout(on: wednesday)?.id, .wednesday)

        restored.setWorkoutDayOverride(nil, date: tuesday)
        XCTAssertEqual(restored.scheduledWorkout(on: tuesday)?.id, .tuesday)
    }

    func testChoosingTheNormalDayClearsOverride() {
        let state = LocalAppState(defaults: defaults)
        let tuesday = date(year: 2026, month: 5, day: 12)

        state.setWorkoutDayOverride(.tuesday, date: tuesday)

        XCTAssertNil(state.workoutDayOverride(on: tuesday))
    }

    func testLegacySnapshotWithOldDayOverrideStillLoads() throws {
        let legacy: [String: Any] = [
            "selectedProgramID": ProgramSeed.defaultProgramID,
            "selectedDayOverride": "friday",
            "setProgress": [],
            "selectedMealIDs": ["meal-1"],
            "checkedGroceryItemIDs": []
        ]
        defaults.set(try JSONSerialization.data(withJSONObject: legacy), forKey: storageKey)

        let state = LocalAppState(defaults: defaults)

        XCTAssertEqual(state.selectedMealIDs, ["meal-1"])
        XCTAssertNil(state.workoutDayOverride(on: date(year: 2026, month: 5, day: 12)))
        XCTAssertEqual(state.weightUnit, .lb)
    }

    func testWeightUnitPersistsAndStampsNewEntries() {
        let state = LocalAppState(defaults: defaults)
        let monday = date(year: 2026, month: 5, day: 11)

        state.weightUnit = .kg
        state.updateSetEntry(exerciseID: "barbell-hip-thrust", setIndex: 0, weightText: "60", repsText: "10", date: monday)

        let restored = LocalAppState(defaults: defaults)
        XCTAssertEqual(restored.weightUnit, .kg)
        XCTAssertEqual(restored.workoutLog(for: monday).setProgress.first?.setEntries.first?.unit, .kg)
    }

    func testLastPerformanceSummaryConvertsToPreferredUnit() {
        let state = LocalAppState(defaults: defaults)
        let lastWeek = date(year: 2026, month: 5, day: 11)
        let today = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: lastWeek)
        state.weightUnit = .kg

        XCTAssertEqual(state.lastPerformanceSummary(exerciseID: "hip-thrust", before: today), "61.2 kg x 10")
    }

    func testPreviousSetHintUsesSameSetFromLastSession() {
        let state = LocalAppState(defaults: defaults)
        let lastWeek = date(year: 2026, month: 5, day: 11)
        let today = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: lastWeek)
        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 1, weightText: "145", repsText: "8", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 1, date: lastWeek)

        let hint0 = state.previousSetHint(exerciseID: "hip-thrust", setIndex: 0, before: today)
        let hint1 = state.previousSetHint(exerciseID: "hip-thrust", setIndex: 1, before: today)
        let hint2 = state.previousSetHint(exerciseID: "hip-thrust", setIndex: 2, before: today)

        XCTAssertEqual(hint0?.weightText, "135")
        XCTAssertEqual(hint0?.repsText, "10")
        XCTAssertEqual(hint1?.weightText, "145")
        XCTAssertEqual(hint2?.weightText, "145", "Extra sets fall back to the last logged set")
    }

    func testCheckingEmptySetAdoptsPreviousHint() {
        let state = LocalAppState(defaults: defaults)
        let lastWeek = date(year: 2026, month: 5, day: 11)
        let today = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: lastWeek)

        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: today)

        let entry = state.setEntry(exerciseID: "hip-thrust", setIndex: 0)
        XCTAssertEqual(entry.weightText, "135")
        XCTAssertEqual(entry.repsText, "10")
        XCTAssertTrue(entry.isCompleted)
    }

    func testCheckingTypedSetKeepsTypedValues() {
        let state = LocalAppState(defaults: defaults)
        let lastWeek = date(year: 2026, month: 5, day: 11)
        let today = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "135", repsText: "10", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: lastWeek)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "140", repsText: "", date: today)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: today)

        let entry = state.setEntry(exerciseID: "hip-thrust", setIndex: 0)
        XCTAssertEqual(entry.weightText, "140")
        XCTAssertEqual(entry.repsText, "")
    }

    func testHintAdoptedInPreferredUnit() {
        let state = LocalAppState(defaults: defaults)
        let lastWeek = date(year: 2026, month: 5, day: 11)
        let today = date(year: 2026, month: 5, day: 18)

        state.updateSetEntry(exerciseID: "hip-thrust", setIndex: 0, weightText: "100", repsText: "10", date: lastWeek)
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: lastWeek)
        state.weightUnit = .kg

        XCTAssertEqual(state.previousSetHint(exerciseID: "hip-thrust", setIndex: 0, before: today)?.weightText, "45.4")
        state.toggleSet(exerciseID: "hip-thrust", setIndex: 0, date: today)

        let entry = state.setEntry(exerciseID: "hip-thrust", setIndex: 0)
        XCTAssertEqual(entry.weightText, "45.4")
        XCTAssertEqual(entry.unit, .kg)
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

    func testPersonalizationProfileAssessmentAndProgramPersist() {
        let state = LocalAppState(defaults: defaults)
        let base = ProgramSeed.defaultProgram
        let generated = TrainingProgram(
            id: base.id,
            name: "\(base.name) - Beginner",
            goal: base.goal,
            summary: "Personalized beginner version.",
            weeklyStructure: base.weeklyStructure,
            prepSteps: base.prepSteps,
            nutritionTargets: NutritionTargets(calories: 1500, proteinGrams: 120, fatGrams: 45, carbsGrams: 130, waterOunces: 100),
            quickProteinAnchors: base.quickProteinAnchors,
            weeklySchedule: base.weeklySchedule,
            mealTemplates: base.mealTemplates
        )
        let profile = UserProfile(
            age: 34,
            heightInches: 66,
            weightPounds: 180,
            experienceLevel: "New to training",
            availableWorkoutDaysPerWeek: 4,
            limitations: "Knee soreness"
        )
        let assessment = FitnessAssessment(
            dateKey: "2026-05-11",
            phase: .baseline,
            pushUpReps: 8,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: 70,
            recoveryHeartRate: 122,
            stepTestDifficulty: 7,
            oneMileTimeSeconds: 960,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 8,
            computedLevel: .beginner
        )
        let personalized = PersonalizedProgram(
            baseProgramID: base.id,
            assignedLevel: .beginner,
            generatedProgram: generated,
            baselineAssessmentID: assessment.id,
            latestAssessmentID: assessment.id,
            startDateKey: "2026-05-11"
        )

        state.userProfile = profile
        state.fitnessAssessments = [assessment]
        state.personalizedPrograms = [personalized]
        state.selectedProgramID = base.id

        let restored = LocalAppState(defaults: defaults)

        XCTAssertEqual(restored.userProfile, profile)
        XCTAssertEqual(restored.fitnessAssessments, [assessment])
        XCTAssertEqual(restored.personalizedPrograms, [personalized])
        XCTAssertEqual(restored.selectedProgram.name, "Lower Body Strength + Recomp - Beginner")
    }

    func testFinalizePersonalizedProgramStoresProfileAssessmentAndGeneratedProgram() {
        let state = LocalAppState(defaults: defaults)
        let profile = UserProfile(
            age: 34,
            heightInches: 66,
            weightPounds: 180,
            experienceLevel: "Some training",
            availableWorkoutDaysPerWeek: 4,
            limitations: ""
        )
        let assessment = FitnessAssessment(
            dateKey: "2026-05-11",
            phase: .baseline,
            pushUpReps: 20,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: 85,
            recoveryHeartRate: nil,
            stepTestDifficulty: 6,
            oneMileTimeSeconds: 760,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 7,
            computedLevel: .beginner
        )

        state.finalizePersonalizedProgram(
            baseProgramID: "weight-loss-foundation",
            profile: profile,
            assessment: assessment,
            startDate: date(year: 2026, month: 5, day: 11)
        )

        XCTAssertEqual(state.selectedProgramID, "weight-loss-foundation")
        XCTAssertEqual(state.userProfile, profile)
        XCTAssertEqual(state.fitnessAssessments.count, 1)
        XCTAssertEqual(state.fitnessAssessments.first?.computedLevel, .moderate)
        XCTAssertEqual(state.personalizedPrograms.first?.assignedLevel, .moderate)
        XCTAssertEqual(state.selectedProgram.name, "Weight Loss Foundation - Moderate")
    }

    func testRecordFitnessRetestUsesStoredProfileAndAdjustsNextBlock() throws {
        let state = LocalAppState(defaults: defaults)
        let profile = UserProfile(
            age: 34,
            heightInches: 66,
            weightPounds: 180,
            experienceLevel: "Some training",
            availableWorkoutDaysPerWeek: 4,
            limitations: ""
        )
        let baseline = FitnessAssessment(
            dateKey: "2026-05-11",
            phase: .baseline,
            pushUpReps: 20,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: 85,
            recoveryHeartRate: nil,
            stepTestDifficulty: 6,
            oneMileTimeSeconds: 760,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 7,
            computedLevel: .beginner
        )
        let retest = FitnessAssessment(
            dateKey: "2026-06-22",
            phase: .week6,
            pushUpReps: 36,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: 118,
            recoveryHeartRate: 108,
            stepTestDifficulty: 6,
            oneMileTimeSeconds: 575,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 6,
            computedLevel: .beginner
        )

        state.finalizePersonalizedProgram(
            baseProgramID: "weight-loss-foundation",
            profile: profile,
            assessment: baseline,
            startDate: date(year: 2026, month: 5, day: 11)
        )
        state.recordFitnessRetest(
            baseProgramID: "weight-loss-foundation",
            phase: .week6,
            assessment: retest,
            date: date(year: 2026, month: 6, day: 22)
        )

        let personalized = try XCTUnwrap(state.personalizedPrograms.first)

        XCTAssertEqual(state.userProfile, profile)
        XCTAssertEqual(state.fitnessAssessments.map(\.phase), [.baseline, .week6])
        XCTAssertEqual(state.fitnessAssessments.last?.computedLevel, .advanced)
        XCTAssertEqual(personalized.baselineAssessmentID, baseline.id)
        XCTAssertEqual(personalized.latestAssessmentID, "week6|2026-06-22")
        XCTAssertEqual(personalized.assignedLevel, .advanced)
        XCTAssertTrue(personalized.generatedProgram.summary.contains("Week 6 retest"))
        XCTAssertTrue(personalized.generatedProgram.weeklyStructure.contains("Weeks 7-12 adjusted after Week 6 retest"))
    }

    func testRecordFitnessRetestRegeneratesAdaptiveExerciseChoices() throws {
        let state = LocalAppState(defaults: defaults)
        let profile = UserProfile(
            age: 34,
            heightInches: 66,
            weightPounds: 180,
            experienceLevel: "Some training",
            availableWorkoutDaysPerWeek: 4,
            limitations: ""
        )
        let baseline = FitnessAssessment(
            dateKey: "2026-05-11",
            phase: .baseline,
            pushUpReps: 4,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: 52,
            recoveryHeartRate: 135,
            stepTestDifficulty: 8,
            oneMileTimeSeconds: 1_120,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 8,
            computedLevel: .beginner
        )
        let week6 = FitnessAssessment(
            dateKey: "2026-06-22",
            phase: .week6,
            pushUpReps: 42,
            pushUpVariation: .standard,
            stepTestDurationSeconds: 180,
            stepCount: 122,
            recoveryHeartRate: 104,
            stepTestDifficulty: 6,
            oneMileTimeSeconds: 540,
            oneMileStyle: .walkRun,
            oneMileDifficulty: 6,
            computedLevel: .beginner
        )

        state.finalizePersonalizedProgram(
            baseProgramID: "weight-loss-foundation",
            profile: profile,
            assessment: baseline,
            startDate: date(year: 2026, month: 5, day: 11)
        )
        XCTAssertTrue(state.selectedProgram.weeklySchedule.flatMap(\.exercises).map(\.name).contains("Incline Push-Up Practice"))

        state.recordFitnessRetest(
            baseProgramID: "weight-loss-foundation",
            phase: .week6,
            assessment: week6,
            date: date(year: 2026, month: 6, day: 22)
        )

        let retestExerciseNames = state.selectedProgram.weeklySchedule.flatMap(\.exercises).map(\.name)

        XCTAssertTrue(retestExerciseNames.contains("Push-Up Progression"))
        XCTAssertTrue(retestExerciseNames.contains("Treadmill Run/Walk Intervals"))
        XCTAssertFalse(retestExerciseNames.contains("Incline Push-Up Practice"))
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

    func testFoodLogsAreScopedBySelectedProgram() {
        let state = LocalAppState(defaults: defaults)
        let date = date(year: 2026, month: 5, day: 11)

        state.toggleFoodMeal("protein-oatmeal", on: true, date: date)
        state.addQuickProtein(25, date: date)
        state.selectProgram(id: "weight-loss-foundation")
        state.toggleFoodMeal("egg-white-breakfast-wrap", on: true, date: date)
        state.addQuickProtein(20, date: date)

        XCTAssertEqual(state.foodLogs.count, 2)
        XCTAssertEqual(state.foodLog(for: date).programID, "weight-loss-foundation")
        XCTAssertEqual(state.foodLog(for: date).checkedMealIDs, ["egg-white-breakfast-wrap"])
        XCTAssertEqual(state.foodLog(for: date).quickProteinAdds, [20])

        state.selectProgram(id: ProgramSeed.defaultProgramID)

        XCTAssertEqual(state.foodLog(for: date).programID, ProgramSeed.defaultProgramID)
        XCTAssertEqual(state.foodLog(for: date).checkedMealIDs, ["protein-oatmeal"])
        XCTAssertEqual(state.foodLog(for: date).quickProteinAdds, [25])
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
        state.weightUnit = .kg

        let data = try XCTUnwrap(defaults.data(forKey: storageKey))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])

        XCTAssertNil(json["quickProteinAdds"])
    }

    func testRestoreDoesNotRewriteSnapshotDuringInit() throws {
        let state = LocalAppState(defaults: defaults)
        state.weightUnit = .kg
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
