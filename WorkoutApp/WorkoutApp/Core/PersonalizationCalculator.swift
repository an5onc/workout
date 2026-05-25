import Foundation

enum PersonalizationCalculator {
    static func level(for profile: UserProfile, assessment: FitnessAssessment) -> TrainingLevel {
        var score = 0

        switch assessment.pushUpReps {
        case 0..<10:
            score += 0
        case 10..<30:
            score += 1
        default:
            score += 2
        }

        switch assessment.stepCount {
        case 0..<70:
            score += 0
        case 70..<105:
            score += 1
        default:
            score += 2
        }

        switch assessment.oneMileTimeSeconds {
        case 0...600:
            score += 2
        case 601...840:
            score += 1
        default:
            score += 0
        }

        if assessment.stepTestDifficulty >= 9 || assessment.oneMileDifficulty >= 9 {
            score -= 1
        }

        var level: TrainingLevel
        switch score {
        case 0...2:
            level = .beginner
        case 3...4:
            level = .moderate
        default:
            level = .advanced
        }

        if hasLimitations(profile), level == .advanced {
            level = .moderate
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
            weeklyStructure: weeklyStructure(for: base, level: assignedLevel),
            prepSteps: base.prepSteps,
            nutritionTargets: nutritionTargets(for: base, profile: profile),
            quickProteinAnchors: base.quickProteinAnchors,
            weeklySchedule: weeklySchedule(for: base, level: assignedLevel),
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

    private static func weeklySchedule(for base: TrainingProgram, level: TrainingLevel) -> [WorkoutDay] {
        base.weeklySchedule.map { day in
            WorkoutDay(
                id: day.id,
                name: day.name,
                focus: day.focus,
                subtitle: day.subtitle,
                isRestDay: day.isRestDay,
                exercises: day.exercises.map { exercise in
                    adjustedExercise(exercise, level: level)
                }
            )
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
            substitutions: exercise.substitutions
        )
    }

    private static func weeklyStructure(for base: TrainingProgram, level: TrainingLevel) -> [String] {
        switch level {
        case .beginner:
            return ["Beginner volume", "Longer rests", "Lower-impact conditioning"] + base.weeklyStructure
        case .moderate:
            return ["Moderate volume", "Standard rests"] + base.weeklyStructure
        case .advanced:
            return ["Advanced volume", "Progressive overload emphasis"] + base.weeklyStructure
        }
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
