import Foundation

struct WorkoutPlanner {
    let schedule: [WorkoutDay]

    func workout(for currentDay: Weekday, override: Weekday?) -> WorkoutDay? {
        let selected = override ?? currentDay
        return schedule.first { $0.id == selected }
    }

    func workout(for date: Date, calendar: Calendar = .current) -> WorkoutDay? {
        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        guard Weekday.allCases.indices.contains(weekdayIndex) else {
            return nil
        }
        return schedule.first { $0.id == Weekday.allCases[weekdayIndex] }
    }

    func activeExercise(in workout: WorkoutDay, progress: [SetProgress]) -> Exercise? {
        guard !workout.isRestDay else { return nil }
        for exercise in workout.exercises {
            let exerciseProgress = progress.first { $0.exerciseID == exercise.id }
            let validSets = 0..<exercise.sets
            let completedCount = exerciseProgress?.completedSets.filter(validSets.contains).count ?? 0
            if completedCount < exercise.sets {
                return exercise
            }
        }
        return nil
    }

    static func summary(for workout: WorkoutDay, log: WorkoutLog, unit: WeightUnit = .lb) -> WorkoutSummary {
        let totalSets = workout.exercises.reduce(0) { $0 + $1.sets }
        var completedSets = 0
        var totalVolume = 0.0

        for exercise in workout.exercises {
            guard let progress = log.setProgress.first(where: { $0.exerciseID == exercise.id }) else {
                continue
            }

            let validSets = Set(0..<exercise.sets)
            let completedEntries = progress.setEntries.filter { entry in
                entry.isCompleted && validSets.contains(entry.setIndex)
            }

            if completedEntries.isEmpty {
                completedSets += progress.completedSets.intersection(validSets).count
            } else {
                completedSets += completedEntries.count
            }

            for entry in completedEntries {
                guard let weight = entry.weight(in: unit), let reps = entry.repsValue else {
                    continue
                }
                totalVolume += weight * Double(reps)
            }
        }

        return WorkoutSummary(
            completedSets: completedSets,
            totalSets: totalSets,
            totalVolume: totalVolume,
            isFinished: log.finishedAt != nil
        )
    }
}

enum WorkoutProgressAdvisor {
    static func suggestion(for exercise: Exercise, progress: SetProgress?, unit: WeightUnit = .lb) -> String {
        guard let progress else {
            return "Start with a controlled first set."
        }

        let completedEntries = progress.setEntries
            .filter { $0.isCompleted }
            .sorted { $0.setIndex < $1.setIndex }
        guard completedEntries.count >= exercise.sets,
              let workingWeight = completedEntries.compactMap({ $0.weight(in: unit) }).max() else {
            if let latestWeight = completedEntries.compactMap({ $0.weight(in: unit) }).last {
                return "Next time: repeat \(formatWeight(latestWeight)) \(unit.symbol)."
            }
            return "Log weight and reps to get a next-time target."
        }

        guard let topRepTarget = topRepTarget(from: exercise.repRange) else {
            return "Next time: repeat \(formatWeight(workingWeight)) \(unit.symbol)."
        }

        let clearedTopRange = completedEntries.allSatisfy { entry in
            guard let reps = Int(entry.repsText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return false
            }
            return reps >= topRepTarget
        }

        if clearedTopRange {
            return "Next time: try \(formatWeight(workingWeight + increment(for: workingWeight, unit: unit))) \(unit.symbol)."
        }

        return "Next time: repeat \(formatWeight(workingWeight)) \(unit.symbol)."
    }

    private static func topRepTarget(from repRange: String) -> Int? {
        let matches = repRange.matches(of: /\d+/)
        return matches.compactMap { Int($0.output) }.max()
    }

    private static func increment(for weight: Double, unit: WeightUnit) -> Double {
        switch unit {
        case .lb:
            return weight >= 100 ? 5 : 2.5
        case .kg:
            return weight >= 45 ? 2.5 : 1
        }
    }

    private static func formatWeight(_ weight: Double) -> String {
        WeightFormatter.string(weight)
    }
}
