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
    }

    private let defaults: UserDefaults
    private let storageKey = "workout.localAppState.v1"
    private var isRestoring = false

    var selectedDayOverride: Weekday? { didSet { save() } }
    var setProgress: [SetProgress] { didSet { save() } }
    var selectedMealIDs: Set<String> { didSet { save() } }
    var checkedGroceryItemIDs: Set<String> { didSet { save() } }
    var quickProteinAdds: [Int] { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedDayOverride = nil
        self.setProgress = []
        self.selectedMealIDs = []
        self.checkedGroceryItemIDs = []
        self.quickProteinAdds = []
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
    }

    private func save() {
        guard !isRestoring else { return }

        let snapshot = Snapshot(
            selectedDayOverride: selectedDayOverride,
            setProgress: setProgress,
            selectedMealIDs: selectedMealIDs,
            checkedGroceryItemIDs: checkedGroceryItemIDs,
            quickProteinAdds: quickProteinAdds
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
