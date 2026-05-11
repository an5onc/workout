import Foundation

struct SetProgress: Identifiable, Hashable, Codable {
    var id: String { exerciseID }
    let exerciseID: String
    var completedSets: Set<Int>
    var weightText: String
    var repsText: String
    var rpeText: String

    init(exerciseID: String, completedSets: Set<Int> = [], weightText: String = "", repsText: String = "", rpeText: String = "") {
        self.exerciseID = exerciseID
        self.completedSets = completedSets
        self.weightText = weightText
        self.repsText = repsText
        self.rpeText = rpeText
    }
}
