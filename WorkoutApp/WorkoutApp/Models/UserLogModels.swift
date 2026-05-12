import Foundation

struct SetEntry: Identifiable, Hashable, Codable {
    var id: Int { setIndex }
    let setIndex: Int
    var weightText: String
    var repsText: String
    var isCompleted: Bool

    init(setIndex: Int, weightText: String = "", repsText: String = "", isCompleted: Bool = false) {
        self.setIndex = setIndex
        self.weightText = weightText
        self.repsText = repsText
        self.isCompleted = isCompleted
    }
}

struct SetProgress: Identifiable, Hashable, Codable {
    var id: String { exerciseID }
    let exerciseID: String
    var completedSets: Set<Int>
    var weightText: String
    var repsText: String
    var rpeText: String
    var setEntries: [SetEntry]

    init(
        exerciseID: String,
        completedSets: Set<Int> = [],
        weightText: String = "",
        repsText: String = "",
        rpeText: String = "",
        setEntries: [SetEntry] = []
    ) {
        self.exerciseID = exerciseID
        self.completedSets = completedSets
        self.weightText = weightText
        self.repsText = repsText
        self.rpeText = rpeText
        self.setEntries = setEntries
    }
}

struct WorkoutLog: Identifiable, Hashable, Codable {
    var id: String { dateKey }
    let dateKey: String
    var setProgress: [SetProgress]
    var finishedAt: Date?
    var selectedSubstitutionIDs: [String: String]

    init(
        dateKey: String,
        setProgress: [SetProgress] = [],
        finishedAt: Date? = nil,
        selectedSubstitutionIDs: [String: String] = [:]
    ) {
        self.dateKey = dateKey
        self.setProgress = setProgress
        self.finishedAt = finishedAt
        self.selectedSubstitutionIDs = selectedSubstitutionIDs
    }

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case setProgress
        case finishedAt
        case selectedSubstitutionIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateKey = try container.decode(String.self, forKey: .dateKey)
        self.setProgress = try container.decodeIfPresent([SetProgress].self, forKey: .setProgress) ?? []
        self.finishedAt = try container.decodeIfPresent(Date.self, forKey: .finishedAt)
        self.selectedSubstitutionIDs = try container.decodeIfPresent([String: String].self, forKey: .selectedSubstitutionIDs) ?? [:]
    }
}

struct WorkoutSummary: Hashable {
    let completedSets: Int
    let totalSets: Int
    let totalVolume: Double
    let isFinished: Bool

    var remainingSets: Int {
        max(totalSets - completedSets, 0)
    }
}

struct FoodLog: Identifiable, Hashable, Codable {
    var id: String { dateKey }
    let dateKey: String
    var checkedMealIDs: Set<String>
    var quickProteinAdds: [Int]

    init(dateKey: String, checkedMealIDs: Set<String> = [], quickProteinAdds: [Int] = []) {
        self.dateKey = dateKey
        self.checkedMealIDs = checkedMealIDs
        self.quickProteinAdds = quickProteinAdds
    }
}

struct WeeklyCheckIn: Identifiable, Hashable, Codable {
    var id: String { dateKey }
    let dateKey: String
    var bodyWeightText: String
    var waistText: String
    var hipsText: String
    var energy: Int
    var soreness: Int
    var notes: String

    init(
        dateKey: String,
        bodyWeightText: String = "",
        waistText: String = "",
        hipsText: String = "",
        energy: Int = 3,
        soreness: Int = 3,
        notes: String = ""
    ) {
        self.dateKey = dateKey
        self.bodyWeightText = bodyWeightText
        self.waistText = waistText
        self.hipsText = hipsText
        self.energy = energy
        self.soreness = soreness
        self.notes = notes
    }
}
