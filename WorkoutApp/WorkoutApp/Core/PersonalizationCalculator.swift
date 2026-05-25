import Foundation

enum PersonalizationCalculator {
    private enum TrainingFocus: Hashable {
        case pushStrengthBase
        case aerobicBase
        case jointFriendlyLoading
        case advancedProgression
    }

    static func level(for profile: UserProfile, assessment: FitnessAssessment) -> TrainingLevel {
        let score = pushUpScore(for: assessment)
            + stepTestScore(for: assessment)
            + mileScore(for: assessment)

        var level: TrainingLevel
        switch score {
        case 0...3:
            level = .beginner
        case 4...6:
            level = .moderate
        default:
            level = .advanced
        }

        if assessment.pushUpVariation != .standard, level == .advanced {
            level = .moderate
        }

        if assessment.stepTestDifficulty >= 9 || assessment.oneMileDifficulty >= 9 {
            level = downshift(level)
        }

        if hasLimitations(profile) {
            level = downshift(level)
        }

        return level
    }

    static func personalizedProgram(
        base: TrainingProgram,
        profile: UserProfile,
        assessment: FitnessAssessment,
        startDate: Date,
        calendar: Calendar = .current
    ) -> PersonalizedProgram {
        let assignedLevel = level(for: profile, assessment: assessment)
        let generatedProgram = TrainingProgram(
            id: base.id,
            name: "\(base.name) - \(assignedLevel.title)",
            goal: base.goal,
            summary: "\(assignedLevel.title) version built from the baseline fitness assessment.",
            weeklyStructure: weeklyStructure(for: base, profile: profile, assessment: assessment, level: assignedLevel),
            prepSteps: base.prepSteps,
            nutritionTargets: nutritionTargets(for: base, profile: profile),
            quickProteinAnchors: base.quickProteinAnchors,
            weeklySchedule: weeklySchedule(for: base, profile: profile, assessment: assessment, level: assignedLevel),
            mealTemplates: base.mealTemplates
        )

        return PersonalizedProgram(
            baseProgramID: base.id,
            assignedLevel: assignedLevel,
            generatedProgram: generatedProgram,
            baselineAssessmentID: assessment.id,
            latestAssessmentID: assessment.id,
            startDateKey: dateKey(for: startDate, calendar: calendar)
        )
    }

    static func isRetestDue(
        program: PersonalizedProgram,
        assessments: [FitnessAssessment],
        on date: Date,
        calendar: Calendar = .current
    ) -> Bool {
        nextRetestPhase(program: program, assessments: assessments, on: date, calendar: calendar) != nil
    }

    static func nextRetestPhase(
        program: PersonalizedProgram,
        assessments: [FitnessAssessment],
        on date: Date,
        calendar: Calendar = .current
    ) -> AssessmentPhase? {
        guard let startDate = parsedDate(from: program.startDateKey, calendar: calendar) else {
            return nil
        }

        let completedPhases = Set(assessments.map(\.phase))
        if !completedPhases.contains(.week6),
           let week6Date = calendar.date(byAdding: .day, value: 42, to: startDate),
           date >= week6Date {
            return .week6
        }

        if completedPhases.contains(.week6),
           !completedPhases.contains(.week12),
           let week12Date = calendar.date(byAdding: .day, value: 84, to: startDate),
           date >= week12Date {
            return .week12
        }

        return nil
    }

    private static func weeklySchedule(
        for base: TrainingProgram,
        profile: UserProfile,
        assessment: FitnessAssessment,
        level: TrainingLevel
    ) -> [WorkoutDay] {
        let focuses = trainingFocuses(for: profile, assessment: assessment, level: level)

        return base.weeklySchedule.map { day in
            WorkoutDay(
                id: day.id,
                name: day.name,
                focus: day.focus,
                subtitle: day.subtitle,
                isRestDay: day.isRestDay,
                exercises: day.exercises.map { exercise in
                    adaptiveExercise(adjustedExercise(exercise, level: level), focuses: focuses)
                }
            )
        }
    }

    private static func pushUpScore(for assessment: FitnessAssessment) -> Int {
        let score: Int
        switch assessment.pushUpReps {
        case 0..<5:
            score = 0
        case 5..<15:
            score = 1
        case 15..<30:
            score = 2
        default:
            score = 3
        }

        return assessment.pushUpVariation == .standard ? score : min(score, 2)
    }

    private static func stepTestScore(for assessment: FitnessAssessment) -> Int {
        switch assessment.stepCount {
        case 0..<60:
            return 0
        case 60..<85:
            return 1
        case 85..<110:
            return 2
        default:
            return 3
        }
    }

    private static func mileScore(for assessment: FitnessAssessment) -> Int {
        switch assessment.oneMileTimeSeconds {
        case 0...600:
            return 3
        case 601...780:
            return 2
        case 781...960:
            return 1
        default:
            return 0
        }
    }

    private static func downshift(_ level: TrainingLevel) -> TrainingLevel {
        switch level {
        case .beginner:
            return .beginner
        case .moderate:
            return .beginner
        case .advanced:
            return .moderate
        }
    }

    private static func adjustedExercise(_ exercise: Exercise, level: TrainingLevel) -> Exercise {
        var sets = exercise.sets
        switch level {
        case .beginner:
            sets = max(1, exercise.sets - 1)
        case .moderate:
            sets = exercise.sets
        case .advanced:
            sets = exercise.sets > 1 ? exercise.sets + 1 : exercise.sets
        }

        return Exercise(
            id: exercise.id,
            name: exercise.name,
            sets: sets,
            repRange: exercise.repRange,
            rest: exercise.rest,
            cue: exercise.cue,
            formCues: exercise.formCues,
            mistakes: exercise.mistakes,
            feel: exercise.feel,
            demoURL: exercise.demoURL,
            substitutions: exercise.substitutions,
            tags: exercise.tags
        )
    }

    private static func weeklyStructure(
        for base: TrainingProgram,
        profile: UserProfile,
        assessment: FitnessAssessment,
        level: TrainingLevel
    ) -> [String] {
        let focuses = trainingFocuses(for: profile, assessment: assessment, level: level)
        let levelStructure: [String]
        switch level {
        case .beginner:
            levelStructure = ["Beginner volume", "Longer rests", "Lower-impact conditioning"]
        case .moderate:
            levelStructure = ["Moderate volume", "Standard rests"]
        case .advanced:
            levelStructure = ["Advanced volume", "Progressive overload emphasis"]
        }

        return levelStructure + focusStructure(for: focuses) + base.weeklyStructure
    }

    private static func trainingFocuses(
        for profile: UserProfile,
        assessment: FitnessAssessment,
        level: TrainingLevel
    ) -> Set<TrainingFocus> {
        var focuses = Set<TrainingFocus>()

        if assessment.pushUpReps < 15 || assessment.pushUpVariation != .standard {
            focuses.insert(.pushStrengthBase)
        }

        if assessment.stepCount < 85 || assessment.oneMileTimeSeconds > 960 {
            focuses.insert(.aerobicBase)
        }

        if hasLimitations(profile) || assessment.stepTestDifficulty >= 9 || assessment.oneMileDifficulty >= 9 {
            focuses.insert(.jointFriendlyLoading)
        }

        if level == .advanced,
           pushUpScore(for: assessment) == 3,
           stepTestScore(for: assessment) == 3,
           mileScore(for: assessment) == 3,
           !hasLimitations(profile) {
            focuses.insert(.advancedProgression)
        }

        return focuses
    }

    private static func focusStructure(for focuses: Set<TrainingFocus>) -> [String] {
        var structure: [String] = []

        if focuses.contains(.pushStrengthBase) {
            structure.append("Push-strength base: incline push-up practice")
        }
        if focuses.contains(.aerobicBase) {
            structure.append("Aerobic base: repeatable treadmill intervals")
        }
        if focuses.contains(.jointFriendlyLoading) {
            structure.append("Joint-friendly loading: stable lower-impact exercise choices")
        }
        if focuses.contains(.advancedProgression) {
            structure.append("Advanced progression: harder push and interval work")
        }

        return structure
    }

    private static func adaptiveExercise(_ exercise: Exercise, focuses: Set<TrainingFocus>) -> Exercise {
        if focuses.contains(.jointFriendlyLoading),
           exercise.tags.contains(.lowerStrength),
           exercise.tags.contains(.unilateral) {
            return handpickedExercise(
                replacing: exercise,
                idSuffix: "supported-split-squat",
                name: "Supported Split Squat",
                sets: max(1, exercise.sets),
                repRange: "8-10/side",
                rest: "60-75s",
                cue: "Use a rack or rail for balance and keep every rep pain-free.",
                tags: [.lowerStrength, .lowImpact, .beginnerFriendly]
            )
        }

        if focuses.contains(.advancedProgression), exercise.tags.contains(.pushStrength) {
            return handpickedExercise(
                replacing: exercise,
                idSuffix: "push-up-progression",
                name: "Push-Up Progression",
                sets: max(3, exercise.sets),
                repRange: "AMRAP clean reps",
                rest: "60s",
                cue: "Use full-body tension and stop one rep before form breaks.",
                tags: [.pushStrength]
            )
        }

        if focuses.contains(.pushStrengthBase), exercise.tags.contains(.pushStrength) {
            return handpickedExercise(
                replacing: exercise,
                idSuffix: "incline-push-up-practice",
                name: "Incline Push-Up Practice",
                sets: max(2, exercise.sets),
                repRange: "6-10 clean reps",
                rest: "60s",
                cue: "Choose an incline that lets every rep stay smooth.",
                tags: [.pushStrength, .beginnerFriendly, .lowImpact]
            )
        }

        if focuses.contains(.advancedProgression), exercise.tags.contains(.conditioning) {
            return handpickedExercise(
                replacing: exercise,
                idSuffix: "run-walk-intervals",
                name: "Treadmill Run/Walk Intervals",
                sets: 1,
                repRange: "18-22 minutes",
                rest: "0.0 incline",
                cue: "Alternate brisk run intervals with controlled walking recoveries.",
                tags: [.conditioning, .treadmill]
            )
        }

        if focuses.contains(.aerobicBase), exercise.tags.contains(.conditioning) {
            return handpickedExercise(
                replacing: exercise,
                idSuffix: "walk-intervals",
                name: "Treadmill Walk Intervals",
                sets: 1,
                repRange: "20 minutes",
                rest: "0.0 incline",
                cue: "Alternate one minute brisk with one minute easy and keep breathing controlled.",
                tags: [.conditioning, .treadmill, .lowImpact, .beginnerFriendly]
            )
        }

        return exercise
    }

    private static func handpickedExercise(
        replacing exercise: Exercise,
        idSuffix: String,
        name: String,
        sets: Int,
        repRange: String,
        rest: String,
        cue: String,
        tags: Set<ExerciseTag>
    ) -> Exercise {
        Exercise(
            id: "\(exercise.id)-\(idSuffix)",
            name: name,
            sets: sets,
            repRange: repRange,
            rest: rest,
            cue: cue,
            formCues: [cue, "Keep the effort repeatable.", "Stop if form breaks."],
            mistakes: ["Rushing the work.", "Pushing past clean technique."],
            feel: "Challenging but repeatable without sharp pain.",
            demoURL: URL(string: "https://www.youtube.com/results?search_query=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)+proper+form"),
            substitutions: exercise.substitutions,
            tags: tags
        )
    }

    private static func nutritionTargets(for base: TrainingProgram, profile: UserProfile) -> NutritionTargets {
        let weight = max(profile.weightPounds, 1)
        let isWeightLoss = base.goal.localizedCaseInsensitiveContains("weight loss")
        let calories = clamp(isWeightLoss ? weight * 11 : weight * 13, min: isWeightLoss ? 1_300 : 1_500, max: isWeightLoss ? 2_200 : 2_700)
        let protein = clamp(Int(Double(weight) * 0.8), min: 90, max: 220)
        let fat = clamp(Int(Double(calories) * 0.25 / 9.0), min: 35, max: 90)
        let carbCalories = max(calories - (protein * 4) - (fat * 9), 0)
        let carbs = carbCalories / 4

        return NutritionTargets(
            calories: calories,
            proteinGrams: protein,
            fatGrams: fat,
            carbsGrams: carbs,
            waterOunces: base.nutritionTargets.waterOunces
        )
    }

    private static func hasLimitations(_ profile: UserProfile) -> Bool {
        !profile.limitations.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func clamp(_ value: Int, min minimum: Int, max maximum: Int) -> Int {
        Swift.max(minimum, Swift.min(value, maximum))
    }

    private static func parsedDate(from dateKey: String, calendar: Calendar) -> Date? {
        dateFormatter(calendar: calendar).date(from: dateKey)
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        dateFormatter(calendar: calendar).string(from: date)
    }

    private static func dateFormatter(calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
