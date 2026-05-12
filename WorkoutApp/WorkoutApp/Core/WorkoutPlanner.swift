import Foundation

struct WorkoutPlanner {
    let schedule: [WorkoutDay]

    func workout(for currentDay: Weekday, override: Weekday?) -> WorkoutDay? {
        let selected = override ?? currentDay
        return schedule.first { $0.id == selected }
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
}

enum WorkoutProgressAdvisor {
    static func suggestion(for exercise: Exercise, progress: SetProgress?) -> String {
        guard let progress else {
            return "Start with a controlled first set."
        }

        let completedEntries = progress.setEntries
            .filter { $0.isCompleted }
            .sorted { $0.setIndex < $1.setIndex }
        guard completedEntries.count >= exercise.sets,
              let workingWeight = completedEntries.compactMap({ numericValue($0.weightText) }).max() else {
            if let latestWeight = completedEntries.compactMap({ numericValue($0.weightText) }).last {
                return "Next time: repeat \(formatWeight(latestWeight)) lb."
            }
            return "Log weight and reps to get a next-time target."
        }

        guard let topRepTarget = topRepTarget(from: exercise.repRange) else {
            return "Next time: repeat \(formatWeight(workingWeight)) lb."
        }

        let clearedTopRange = completedEntries.allSatisfy { entry in
            guard let reps = Int(entry.repsText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return false
            }
            return reps >= topRepTarget
        }

        if clearedTopRange {
            return "Next time: try \(formatWeight(workingWeight + increment(for: workingWeight))) lb."
        }

        return "Next time: repeat \(formatWeight(workingWeight)) lb."
    }

    private static func topRepTarget(from repRange: String) -> Int? {
        let matches = repRange.matches(of: /\d+/)
        return matches.compactMap { Int($0.output) }.max()
    }

    private static func numericValue(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func increment(for weight: Double) -> Double {
        weight >= 100 ? 5 : 2.5
    }

    private static func formatWeight(_ weight: Double) -> String {
        if weight.rounded() == weight {
            return String(Int(weight))
        }
        return String(format: "%.1f", weight)
    }
}
