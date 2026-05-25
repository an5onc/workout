import Foundation
import Observation

@Observable
@MainActor
final class LocalAppState {
    private struct Snapshot: Codable {
        var selectedProgramID: String?
        var selectedDayOverride: Weekday?
        var setProgress: [SetProgress]
        var selectedMealIDs: Set<String>
        var checkedGroceryItemIDs: Set<String>
        var quickProteinAdds: [Int]?
        var foodLogs: [FoodLog]?
        var workoutLogs: [WorkoutLog]?
        var weeklyCheckIns: [WeeklyCheckIn]?
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "workout.localAppState.v1"
    @ObservationIgnored private var isRestoring = false

    var selectedProgramID: String { didSet { save() } }
    var selectedDayOverride: Weekday? { didSet { save() } }
    var setProgress: [SetProgress] { didSet { save() } }
    var selectedMealIDs: Set<String> { didSet { save() } }
    var checkedGroceryItemIDs: Set<String> { didSet { save() } }
    var foodLogs: [FoodLog] { didSet { save() } }
    var workoutLogs: [WorkoutLog] { didSet { save() } }
    var weeklyCheckIns: [WeeklyCheckIn] { didSet { save() } }

    var selectedProgram: TrainingProgram {
        ProgramSeed.program(id: selectedProgramID) ?? ProgramSeed.defaultProgram
    }

    func selectProgram(id: String) {
        guard id != selectedProgramID else { return }
        selectedProgramID = id
        selectedMealIDs.removeAll()
        checkedGroceryItemIDs.removeAll()
        setProgress = workoutLog(for: Date()).setProgress
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedProgramID = ProgramSeed.defaultProgramID
        self.selectedDayOverride = nil
        self.setProgress = []
        self.selectedMealIDs = []
        self.checkedGroceryItemIDs = []
        self.foodLogs = []
        self.workoutLogs = []
        self.weeklyCheckIns = []
        restore()
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
        let index = setProgress.firstIndex { $0.exerciseID == exerciseID }
        if let index {
            if setProgress[index].completedSets.contains(setIndex) {
                setProgress[index].completedSets.remove(setIndex)
            } else {
                setProgress[index].completedSets.insert(setIndex)
            }
            syncSetEntryCompletion(exerciseProgressIndex: index, setIndex: setIndex)
        } else {
            setProgress.append(SetProgress(
                exerciseID: exerciseID,
                completedSets: [setIndex],
                setEntries: [SetEntry(setIndex: setIndex, isCompleted: true)]
            ))
        }
        upsertWorkoutLog(for: date)
    }

    func setEntry(exerciseID: String, setIndex: Int) -> SetEntry {
        progress(for: exerciseID).setEntries.first { $0.setIndex == setIndex } ?? SetEntry(setIndex: setIndex)
    }

    func updateSetEntry(exerciseID: String, setIndex: Int, weightText: String, repsText: String, date: Date = Date()) {
        let progressIndex = ensureProgressIndex(for: exerciseID)
        let existingCompletion = setProgress[progressIndex].completedSets.contains(setIndex)
        let entry = SetEntry(
            setIndex: setIndex,
            weightText: weightText,
            repsText: repsText,
            isCompleted: existingCompletion
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
        let key = dateKey(for: date)
        let previousLogs = workoutLogs
            .filter { $0.programID == selectedProgramID && $0.dateKey < key }
            .sorted { $0.dateKey > $1.dateKey }

        for log in previousLogs {
            guard let progress = log.setProgress.first(where: { $0.exerciseID == exerciseID }) else { continue }
            let completedEntries = progress.setEntries
                .filter { $0.isCompleted && !$0.weightText.isEmpty && !$0.repsText.isEmpty }
                .sorted { $0.setIndex < $1.setIndex }
            guard let firstWeight = completedEntries.first?.weightText, !completedEntries.isEmpty else { continue }
            let reps = completedEntries.map(\.repsText).joined(separator: ", ")
            return "\(firstWeight) lb x \(reps)"
        }
        return nil
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

    private func restore() {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        isRestoring = true
        defer { isRestoring = false }

        selectedProgramID = snapshot.selectedProgramID ?? ProgramSeed.defaultProgramID
        selectedDayOverride = snapshot.selectedDayOverride
        setProgress = snapshot.setProgress
        selectedMealIDs = snapshot.selectedMealIDs
        checkedGroceryItemIDs = snapshot.checkedGroceryItemIDs
        foodLogs = snapshot.foodLogs ?? []
        workoutLogs = snapshot.workoutLogs ?? []
        weeklyCheckIns = snapshot.weeklyCheckIns ?? []
    }

    private func save() {
        guard !isRestoring else { return }

        let snapshot = Snapshot(
            selectedProgramID: selectedProgramID,
            selectedDayOverride: selectedDayOverride,
            setProgress: setProgress,
            selectedMealIDs: selectedMealIDs,
            checkedGroceryItemIDs: checkedGroceryItemIDs,
            quickProteinAdds: nil,
            foodLogs: foodLogs,
            workoutLogs: workoutLogs,
            weeklyCheckIns: weeklyCheckIns
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

    private func ensureProgressIndex(for exerciseID: String) -> Int {
        if let index = setProgress.firstIndex(where: { $0.exerciseID == exerciseID }) {
            return index
        }
        setProgress.append(SetProgress(exerciseID: exerciseID))
        return setProgress.count - 1
    }

    private func syncSetEntryCompletion(exerciseProgressIndex: Int, setIndex: Int) {
        var entry = setProgress[exerciseProgressIndex].setEntries.first { $0.setIndex == setIndex } ?? SetEntry(setIndex: setIndex)
        entry.isCompleted = setProgress[exerciseProgressIndex].completedSets.contains(setIndex)
        upsertSetEntry(entry, exerciseProgressIndex: exerciseProgressIndex)
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

    @ObservationIgnored private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
