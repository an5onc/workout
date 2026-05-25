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
    var id: String { "\(programID)|\(dateKey)" }
    let dateKey: String
    var programID: String
    var setProgress: [SetProgress]
    var finishedAt: Date?
    var selectedSubstitutionIDs: [String: String]

    init(
        dateKey: String,
        programID: String = ProgramSeed.defaultProgramID,
        setProgress: [SetProgress] = [],
        finishedAt: Date? = nil,
        selectedSubstitutionIDs: [String: String] = [:]
    ) {
        self.dateKey = dateKey
        self.programID = programID
        self.setProgress = setProgress
        self.finishedAt = finishedAt
        self.selectedSubstitutionIDs = selectedSubstitutionIDs
    }

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case programID
        case setProgress
        case finishedAt
        case selectedSubstitutionIDs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateKey = try container.decode(String.self, forKey: .dateKey)
        self.programID = try container.decodeIfPresent(String.self, forKey: .programID) ?? ProgramSeed.defaultProgramID
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
    var id: String { "\(programID)|\(dateKey)" }
    let dateKey: String
    var programID: String
    var checkedMealIDs: Set<String>
    var quickProteinAdds: [Int]

    init(
        dateKey: String,
        programID: String = ProgramSeed.defaultProgramID,
        checkedMealIDs: Set<String> = [],
        quickProteinAdds: [Int] = []
    ) {
        self.dateKey = dateKey
        self.programID = programID
        self.checkedMealIDs = checkedMealIDs
        self.quickProteinAdds = quickProteinAdds
    }

    private enum CodingKeys: String, CodingKey {
        case dateKey
        case programID
        case checkedMealIDs
        case quickProteinAdds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateKey = try container.decode(String.self, forKey: .dateKey)
        self.programID = try container.decodeIfPresent(String.self, forKey: .programID) ?? ProgramSeed.defaultProgramID
        self.checkedMealIDs = try container.decodeIfPresent(Set<String>.self, forKey: .checkedMealIDs) ?? []
        self.quickProteinAdds = try container.decodeIfPresent([Int].self, forKey: .quickProteinAdds) ?? []
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

enum TrainingLevel: String, CaseIterable, Identifiable, Codable {
    case beginner
    case moderate
    case advanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: "Beginner"
        case .moderate: "Moderate"
        case .advanced: "Advanced"
        }
    }
}

enum AssessmentPhase: String, CaseIterable, Identifiable, Codable {
    case baseline
    case week6
    case week12

    var id: String { rawValue }

    var title: String {
        switch self {
        case .baseline: "Baseline"
        case .week6: "Week 6"
        case .week12: "Week 12"
        }
    }
}

enum PushUpVariation: String, CaseIterable, Identifiable, Codable {
    case standard
    case knee
    case incline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: "Standard"
        case .knee: "Knee"
        case .incline: "Incline"
        }
    }
}

enum MileTestStyle: String, CaseIterable, Identifiable, Codable {
    case walk
    case run
    case walkRun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walk: "Walk"
        case .run: "Run"
        case .walkRun: "Walk/run"
        }
    }
}

struct UserProfile: Hashable, Codable {
    var age: Int
    var heightInches: Int
    var weightPounds: Int
    var experienceLevel: String
    var availableWorkoutDaysPerWeek: Int
    var limitations: String
}

struct FitnessAssessment: Identifiable, Hashable, Codable {
    var id: String { "\(phase.rawValue)|\(dateKey)" }
    let dateKey: String
    let phase: AssessmentPhase
    var pushUpReps: Int
    var pushUpVariation: PushUpVariation
    var stepTestDurationSeconds: Int
    var stepCount: Int
    var recoveryHeartRate: Int?
    var stepTestDifficulty: Int
    var oneMileTimeSeconds: Int
    var oneMileStyle: MileTestStyle
    var oneMileDifficulty: Int
    var computedLevel: TrainingLevel
}

struct PersonalizedProgram: Identifiable, Hashable, Codable {
    var id: String { baseProgramID }
    let baseProgramID: String
    var assignedLevel: TrainingLevel
    var generatedProgram: TrainingProgram
    var baselineAssessmentID: String
    var latestAssessmentID: String
    var startDateKey: String
}
