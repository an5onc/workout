import Foundation
import Observation

@Observable
@MainActor
final class LocalAppState {
    private struct Snapshot: Codable {
        var selectedDayOverride: Weekday?
        var setProgress: [SetProgress]
        var selectedMealIDs: Set<String>
        var checkedGroceryItemIDs: Set<String>
        var quickProteinAdds: [Int]
        var foodLogs: [FoodLog]?
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let storageKey = "workout.localAppState.v1"
    @ObservationIgnored private var isRestoring = false

    var selectedDayOverride: Weekday? { didSet { save() } }
    var setProgress: [SetProgress] { didSet { save() } }
    var selectedMealIDs: Set<String> { didSet { save() } }
    var checkedGroceryItemIDs: Set<String> { didSet { save() } }
    var quickProteinAdds: [Int] { didSet { save() } }
    var foodLogs: [FoodLog] { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedDayOverride = nil
        self.setProgress = []
        self.selectedMealIDs = []
        self.checkedGroceryItemIDs = []
        self.quickProteinAdds = []
        self.foodLogs = []
        restore()
    }

    func progress(for exerciseID: String) -> SetProgress {
        if let existing = setProgress.first(where: { $0.exerciseID == exerciseID }) {
            return existing
        }
        return SetProgress(exerciseID: exerciseID)
    }

    func toggleSet(exerciseID: String, setIndex: Int) {
        let index = setProgress.firstIndex { $0.exerciseID == exerciseID }
        if let index {
            if setProgress[index].completedSets.contains(setIndex) {
                setProgress[index].completedSets.remove(setIndex)
            } else {
                setProgress[index].completedSets.insert(setIndex)
            }
        } else {
            setProgress.append(SetProgress(exerciseID: exerciseID, completedSets: [setIndex]))
        }
    }

    func selectedMeals(from templates: [MealTemplate]) -> [MealTemplate] {
        templates.filter { selectedMealIDs.contains($0.id) }
    }

    func foodLog(for date: Date) -> FoodLog {
        let key = dateKey(for: date)
        return foodLogs.first { $0.dateKey == key } ?? FoodLog(dateKey: key)
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

        selectedDayOverride = snapshot.selectedDayOverride
        setProgress = snapshot.setProgress
        selectedMealIDs = snapshot.selectedMealIDs
        checkedGroceryItemIDs = snapshot.checkedGroceryItemIDs
        quickProteinAdds = snapshot.quickProteinAdds
        foodLogs = snapshot.foodLogs ?? []
    }

    private func save() {
        guard !isRestoring else { return }

        let snapshot = Snapshot(
            selectedDayOverride: selectedDayOverride,
            setProgress: setProgress,
            selectedMealIDs: selectedMealIDs,
            checkedGroceryItemIDs: checkedGroceryItemIDs,
            quickProteinAdds: quickProteinAdds,
            foodLogs: foodLogs
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func upsertFoodLog(_ log: FoodLog) {
        if let index = foodLogs.firstIndex(where: { $0.dateKey == log.dateKey }) {
            foodLogs[index] = log
        } else {
            foodLogs.append(log)
        }
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
