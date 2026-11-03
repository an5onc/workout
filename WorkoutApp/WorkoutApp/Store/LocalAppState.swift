import Foundation
import Observation

@Observable
@MainActor
final class LocalAppState {
    private struct Snapshot: Codable {
        var selectedProgramID: String?
        var dayOverrides: [String: Weekday]?
        var loadedDateKey: String?
        var weightUnit: WeightUnit?
        var setProgress: [SetProgress]
        var selectedMealIDs: Set<String>
        var checkedGroceryItemIDs: Set<String>
        var quickProteinAdds: [Int]?
        var foodLogs: [FoodLog]?
        var workoutLogs: [WorkoutLog]?
        var weeklyCheckIns: [WeeklyCheckIn]?
        var userProfile: UserProfile?
        var fitnessAssessments: [FitnessAssessment]?
        var personalizedPrograms: [PersonalizedProgram]?
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "workout.localAppState.v1"
    @ObservationIgnored private var isRestoring = false

    var selectedProgramID: String { didSet { save() } }
    /// Workout swaps keyed by date ("yyyy-MM-dd"), so a swap never leaks into another day.
    var dayOverrides: [String: Weekday] { didSet { save() } }
    var weightUnit: WeightUnit { didSet { save() } }
    /// Sets for the day in `loadedDateKey`. Always go through `prepareDay(_:)` before reading or writing for a date.
    var setProgress: [SetProgress] { didSet { save() } }
    private(set) var loadedDateKey: String? { didSet { save() } }
    var selectedMealIDs: Set<String> { didSet { save() } }
    var checkedGroceryItemIDs: Set<String> { didSet { save() } }
    var foodLogs: [FoodLog] { didSet { save() } }
    var workoutLogs: [WorkoutLog] { didSet { save() } }
    var weeklyCheckIns: [WeeklyCheckIn] { didSet { save() } }
    var userProfile: UserProfile? { didSet { save() } }
    var fitnessAssessments: [FitnessAssessment] { didSet { save() } }
    var personalizedPrograms: [PersonalizedProgram] { didSet { save() } }

    var selectedProgram: TrainingProgram {
        if let personalizedProgram = personalizedPrograms.first(where: { $0.baseProgramID == selectedProgramID }) {
            return personalizedProgram.generatedProgram
        }
        return ProgramSeed.program(id: selectedProgramID) ?? ProgramSeed.defaultProgram
    }

    func selectProgram(id: String) {
        guard id != selectedProgramID else { return }
        selectedProgramID = id
        selectedMealIDs.removeAll()
        checkedGroceryItemIDs.removeAll()
        loadDay(Date())
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedProgramID = ProgramSeed.defaultProgramID
        self.dayOverrides = [:]
        self.weightUnit = .lb
        self.setProgress = []
        self.loadedDateKey = nil
        self.selectedMealIDs = []
        self.checkedGroceryItemIDs = []
        self.foodLogs = []
        self.workoutLogs = []
        self.weeklyCheckIns = []
        self.userProfile = nil
        self.fitnessAssessments = []
        self.personalizedPrograms = []
        restore()
    }

    /// Swaps in the given day's own sets when the day changes. Safe to call repeatedly.
    func prepareDay(_ date: Date) {
        guard dateKey(for: date) != loadedDateKey else { return }
        loadDay(date)
    }

    private func loadDay(_ date: Date) {
        setProgress = workoutLog(for: date).setProgress
        loadedDateKey = dateKey(for: date)
    }

    func workoutDayOverride(on date: Date) -> Weekday? {
        dayOverrides[dateKey(for: date)]
    }

    /// Pass `nil` (or the date's own weekday) to go back to the normal schedule.
    func setWorkoutDayOverride(_ weekday: Weekday?, date: Date) {
        let key = dateKey(for: date)
        if let weekday, weekday != Self.weekday(for: date) {
            dayOverrides[key] = weekday
        } else {
            dayOverrides.removeValue(forKey: key)
        }
    }

    func scheduledWorkout(on date: Date) -> WorkoutDay? {
        WorkoutPlanner(schedule: selectedProgram.weeklySchedule)
            .workout(for: Self.weekday(for: date), override: workoutDayOverride(on: date))
    }

    static func weekday(for date: Date, calendar: Calendar = .current) -> Weekday {
        Weekday.allCases[calendar.component(.weekday, from: date) - 1]
    }

    func previousSetHint(exerciseID: String, setIndex: Int, before date: Date = Date()) -> SetEntry? {
        WorkoutHistory.previousSetHint(
            exerciseID: exerciseID,
            setIndex: setIndex,
            logs: workoutLogs,
            programID: selectedProgramID,
            beforeDateKey: dateKey(for: date),
            unit: weightUnit
        )
    }

    func progress(for exerciseID: String) -> SetProgress {
        if let existing = setProgress.first(where: { $0.exerciseID == exerciseID }) {
            return existing
        }
        return SetProgress(exerciseID: exerciseID)
    }

    func toggleSet(exerciseID: String, setIndex: Int) {
        toggleSet(exerciseID: exerciseID, setIndex: setIndex, date: Date())
    }

    func toggleSet(exerciseID: String, setIndex: Int, date: Date) {
        prepareDay(date)
        let index = ensureProgressIndex(for: exerciseID)
        var entry = setProgress[index].setEntries.first { $0.setIndex == setIndex } ?? SetEntry(setIndex: setIndex)
        let isCompleting = !setProgress[index].completedSets.contains(setIndex)
        entry.isCompleted = isCompleting

        // Checking off an untouched set logs what was shown as the hint (last time's numbers).
        if isCompleting,
           entry.weightText.trimmingCharacters(in: .whitespaces).isEmpty,
           entry.repsText.trimmingCharacters(in: .whitespaces).isEmpty,
           let hint = previousSetHint(exerciseID: exerciseID, setIndex: setIndex, before: date) {
            entry.weightText = hint.weightText
            entry.repsText = hint.repsText
            entry.unit = weightUnit
        }

        upsertSetEntry(entry, exerciseProgressIndex: index)
        upsertWorkoutLog(for: date)
    }

    func setEntry(exerciseID: String, setIndex: Int) -> SetEntry {
        progress(for: exerciseID).setEntries.first { $0.setIndex == setIndex } ?? SetEntry(setIndex: setIndex)
    }

    func updateSetEntry(exerciseID: String, setIndex: Int, weightText: String, repsText: String, date: Date = Date()) {
        prepareDay(date)
        let progressIndex = ensureProgressIndex(for: exerciseID)
        let existingCompletion = setProgress[progressIndex].completedSets.contains(setIndex)
        let entry = SetEntry(
            setIndex: setIndex,
            weightText: weightText,
            repsText: repsText,
            isCompleted: existingCompletion,
            unit: weightUnit
        )
        upsertSetEntry(entry, exerciseProgressIndex: progressIndex)
        upsertWorkoutLog(for: date)
    }

    func workoutLog(for date: Date) -> WorkoutLog {
        let key = dateKey(for: date)
        return workoutLogs.first { $0.dateKey == key && $0.programID == selectedProgramID } ?? WorkoutLog(dateKey: key, programID: selectedProgramID)
    }

    func selectSubstitution(exerciseID: String, substitutionID: String?, date: Date = Date()) {
        var log = workoutLog(for: date)
        if let substitutionID {
            log.selectedSubstitutionIDs[exerciseID] = substitutionID
        } else {
            log.selectedSubstitutionIDs.removeValue(forKey: exerciseID)
        }
        upsertWorkoutLog(log)
    }

    func selectedSubstitutionID(exerciseID: String, date: Date = Date()) -> String? {
        workoutLog(for: date).selectedSubstitutionIDs[exerciseID]
    }

    func finishWorkout(date: Date = Date()) {
        var log = workoutLog(for: date)
        log.finishedAt = date
        upsertWorkoutLog(log)
    }

    func isWorkoutFinished(date: Date = Date()) -> Bool {
        workoutLog(for: date).finishedAt != nil
    }

    func lastPerformanceSummary(exerciseID: String, before date: Date = Date()) -> String? {
        WorkoutHistory.lastPerformanceSummary(
            exerciseID: exerciseID,
            logs: workoutLogs,
            programID: selectedProgramID,
            beforeDateKey: dateKey(for: date),
            unit: weightUnit
        )
    }

    func weeklyCheckIn(for date: Date) -> WeeklyCheckIn {
        let key = dateKey(for: date)
        return weeklyCheckIns.first { $0.dateKey == key } ?? WeeklyCheckIn(dateKey: key)
    }

    func updateWeeklyCheckIn(
        date: Date,
        bodyWeightText: String,
        waistText: String,
        hipsText: String,
        energy: Int,
        soreness: Int,
        notes: String
    ) {
        let checkIn = WeeklyCheckIn(
            dateKey: dateKey(for: date),
            bodyWeightText: bodyWeightText,
            waistText: waistText,
            hipsText: hipsText,
            energy: min(max(energy, 1), 5),
            soreness: min(max(soreness, 1), 5),
            notes: notes
        )
        if let index = weeklyCheckIns.firstIndex(where: { $0.dateKey == checkIn.dateKey }) {
            weeklyCheckIns[index] = checkIn
        } else {
            weeklyCheckIns.append(checkIn)
        }
    }

    func selectedMeals(from templates: [MealTemplate]) -> [MealTemplate] {
        templates.filter { selectedMealIDs.contains($0.id) }
    }

    func foodLog(for date: Date) -> FoodLog {
        let key = dateKey(for: date)
        return foodLogs.first { $0.dateKey == key && $0.programID == selectedProgramID } ?? FoodLog(dateKey: key, programID: selectedProgramID)
    }

    func selectedFoodMeals(from templates: [MealTemplate], date: Date) -> [MealTemplate] {
        let checkedMealIDs = foodLog(for: date).checkedMealIDs
        return templates.filter { checkedMealIDs.contains($0.id) }
    }

    func toggleFoodMeal(_ mealID: String, on isSelected: Bool, date: Date) {
        var log = foodLog(for: date)
        if isSelected {
            log.checkedMealIDs.insert(mealID)
        } else {
            log.checkedMealIDs.remove(mealID)
        }
        upsertFoodLog(log)
    }

    func addQuickProtein(_ grams: Int, date: Date) {
        var log = foodLog(for: date)
        log.quickProteinAdds.append(grams)
        upsertFoodLog(log)
    }

    func removeLastQuickProteinAdd(date: Date) {
        var log = foodLog(for: date)
        _ = log.quickProteinAdds.popLast()
        upsertFoodLog(log)
    }

    func clearQuickProteinAdds(date: Date) {
        var log = foodLog(for: date)
        log.quickProteinAdds.removeAll()
        upsertFoodLog(log)
    }

    func finalizePersonalizedProgram(
        baseProgramID: String,
        profile: UserProfile,
        assessment: FitnessAssessment,
        startDate: Date = Date()
    ) {
        guard let baseProgram = ProgramSeed.program(id: baseProgramID) else {
            return
        }

        let computedLevel = PersonalizationCalculator.level(for: profile, assessment: assessment)
        var normalizedAssessment = assessment
        normalizedAssessment.computedLevel = computedLevel
        let personalizedProgram = PersonalizationCalculator.personalizedProgram(
            base: baseProgram,
            profile: profile,
            assessment: normalizedAssessment,
            startDate: startDate
        )

        userProfile = profile
        upsertFitnessAssessment(normalizedAssessment)
        upsertPersonalizedProgram(personalizedProgram)
        selectedProgramID = baseProgramID
        selectedMealIDs.removeAll()
        checkedGroceryItemIDs.removeAll()
        loadDay(startDate)
    }

    func recordFitnessRetest(
        baseProgramID: String,
        phase: AssessmentPhase,
        assessment: FitnessAssessment,
        date: Date = Date()
    ) {
        guard phase != .baseline,
              let profile = userProfile,
              let baseProgram = ProgramSeed.program(id: baseProgramID),
              let existingProgram = personalizedPrograms.first(where: { $0.baseProgramID == baseProgramID }) else {
            return
        }

        let normalizedAssessment = normalizedRetestAssessment(
            assessment,
            phase: phase,
            date: date,
            profile: profile
        )
        var personalizedProgram = PersonalizationCalculator.personalizedProgram(
            base: baseProgram,
            profile: profile,
            assessment: normalizedAssessment,
            startDate: parsedDate(from: existingProgram.startDateKey) ?? date
        )
        personalizedProgram.baselineAssessmentID = existingProgram.baselineAssessmentID
        personalizedProgram.latestAssessmentID = normalizedAssessment.id
        personalizedProgram.generatedProgram = retestAdjustedProgram(
            personalizedProgram.generatedProgram,
            phase: phase,
            level: personalizedProgram.assignedLevel
        )

        upsertFitnessAssessment(normalizedAssessment)
        upsertPersonalizedProgram(personalizedProgram)
        selectedProgramID = baseProgramID
        selectedMealIDs.removeAll()
        checkedGroceryItemIDs.removeAll()
        loadDay(date)
    }

    private func restore() {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        isRestoring = true
        defer { isRestoring = false }

        selectedProgramID = snapshot.selectedProgramID ?? ProgramSeed.defaultProgramID
        dayOverrides = snapshot.dayOverrides ?? [:]
        weightUnit = snapshot.weightUnit ?? .lb
        setProgress = snapshot.setProgress
        // Snapshots saved before this field existed have nil, so the next prepareDay reloads from the day's log.
        loadedDateKey = snapshot.loadedDateKey
        selectedMealIDs = snapshot.selectedMealIDs
        checkedGroceryItemIDs = snapshot.checkedGroceryItemIDs
        foodLogs = snapshot.foodLogs ?? []
        workoutLogs = snapshot.workoutLogs ?? []
        weeklyCheckIns = snapshot.weeklyCheckIns ?? []
        userProfile = snapshot.userProfile
        fitnessAssessments = snapshot.fitnessAssessments ?? []
        personalizedPrograms = snapshot.personalizedPrograms ?? []
    }

    private func save() {
        guard !isRestoring else { return }

        let snapshot = Snapshot(
            selectedProgramID: selectedProgramID,
            dayOverrides: dayOverrides,
            loadedDateKey: loadedDateKey,
            weightUnit: weightUnit,
            setProgress: setProgress,
            selectedMealIDs: selectedMealIDs,
            checkedGroceryItemIDs: checkedGroceryItemIDs,
            quickProteinAdds: nil,
            foodLogs: foodLogs,
            workoutLogs: workoutLogs,
            weeklyCheckIns: weeklyCheckIns,
            userProfile: userProfile,
            fitnessAssessments: fitnessAssessments,
            personalizedPrograms: personalizedPrograms
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func upsertFoodLog(_ log: FoodLog) {
        if let index = foodLogs.firstIndex(where: { $0.dateKey == log.dateKey && $0.programID == log.programID }) {
            foodLogs[index] = log
        } else {
            foodLogs.append(log)
        }
    }

    private func upsertWorkoutLog(_ log: WorkoutLog) {
        if let index = workoutLogs.firstIndex(where: { $0.dateKey == log.dateKey && $0.programID == log.programID }) {
            workoutLogs[index] = log
        } else {
            workoutLogs.append(log)
        }
    }

    private func upsertFitnessAssessment(_ assessment: FitnessAssessment) {
        if let index = fitnessAssessments.firstIndex(where: { $0.id == assessment.id }) {
            fitnessAssessments[index] = assessment
        } else {
            fitnessAssessments.append(assessment)
        }
    }

    private func upsertPersonalizedProgram(_ program: PersonalizedProgram) {
        if let index = personalizedPrograms.firstIndex(where: { $0.baseProgramID == program.baseProgramID }) {
            personalizedPrograms[index] = program
        } else {
            personalizedPrograms.append(program)
        }
    }

    private func normalizedRetestAssessment(
        _ assessment: FitnessAssessment,
        phase: AssessmentPhase,
        date: Date,
        profile: UserProfile
    ) -> FitnessAssessment {
        var normalized = FitnessAssessment(
            dateKey: dateKey(for: date),
            phase: phase,
            pushUpReps: assessment.pushUpReps,
            pushUpVariation: assessment.pushUpVariation,
            stepTestDurationSeconds: assessment.stepTestDurationSeconds,
            stepCount: assessment.stepCount,
            recoveryHeartRate: assessment.recoveryHeartRate,
            stepTestDifficulty: assessment.stepTestDifficulty,
            oneMileTimeSeconds: assessment.oneMileTimeSeconds,
            oneMileStyle: assessment.oneMileStyle,
            oneMileDifficulty: assessment.oneMileDifficulty,
            computedLevel: assessment.computedLevel
        )
        normalized.computedLevel = PersonalizationCalculator.level(for: profile, assessment: normalized)
        return normalized
    }

    private func retestAdjustedProgram(
        _ program: TrainingProgram,
        phase: AssessmentPhase,
        level: TrainingLevel
    ) -> TrainingProgram {
        let adjustmentLabel: String
        switch phase {
        case .baseline:
            adjustmentLabel = "Baseline assessment"
        case .week6:
            adjustmentLabel = "Weeks 7-12 adjusted after Week 6 retest"
        case .week12:
            adjustmentLabel = "Week 12 final assessment recorded"
        }

        return TrainingProgram(
            id: program.id,
            name: program.name,
            goal: program.goal,
            summary: "\(program.summary) \(phase.title) retest assigned \(level.title) training for the next block.",
            weeklyStructure: [adjustmentLabel] + program.weeklyStructure.filter { $0 != adjustmentLabel },
            prepSteps: program.prepSteps,
            nutritionTargets: program.nutritionTargets,
            quickProteinAnchors: program.quickProteinAnchors,
            weeklySchedule: program.weeklySchedule,
            mealTemplates: program.mealTemplates
        )
    }

    private func ensureProgressIndex(for exerciseID: String) -> Int {
        if let index = setProgress.firstIndex(where: { $0.exerciseID == exerciseID }) {
            return index
        }
        setProgress.append(SetProgress(exerciseID: exerciseID))
        return setProgress.count - 1
    }

    private func upsertSetEntry(_ entry: SetEntry, exerciseProgressIndex: Int) {
        if let entryIndex = setProgress[exerciseProgressIndex].setEntries.firstIndex(where: { $0.setIndex == entry.setIndex }) {
            setProgress[exerciseProgressIndex].setEntries[entryIndex] = entry
        } else {
            setProgress[exerciseProgressIndex].setEntries.append(entry)
        }
        if entry.isCompleted {
            setProgress[exerciseProgressIndex].completedSets.insert(entry.setIndex)
        } else {
            setProgress[exerciseProgressIndex].completedSets.remove(entry.setIndex)
        }
        setProgress[exerciseProgressIndex].setEntries.sort { $0.setIndex < $1.setIndex }
    }

    private func upsertWorkoutLog(for date: Date) {
        let key = dateKey(for: date)
        var log = workoutLogs.first { $0.dateKey == key && $0.programID == selectedProgramID } ?? WorkoutLog(dateKey: key, programID: selectedProgramID)
        log.programID = selectedProgramID
        log.setProgress = setProgress
        upsertWorkoutLog(log)
    }

    private func dateKey(for date: Date) -> String {
        Self.dateKeyFormatter.string(from: date)
    }

    private func parsedDate(from dateKey: String?) -> Date? {
        guard let dateKey else {
            return nil
        }
        return Self.dateKeyFormatter.date(from: dateKey)
    }

    @ObservationIgnored private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
