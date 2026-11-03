import Foundation

struct ExerciseRecord: Hashable {
    let exerciseID: String
    let weight: Double
    let reps: Int
}

/// Read-only queries over saved workout logs. All weights come back in the requested unit.
enum WorkoutHistory {
    static func sessionSummary(for progress: SetProgress, unit: WeightUnit) -> String? {
        let entries = loggedEntries(in: progress)
        guard let first = entries.first, let weight = first.weight(in: unit) else {
            return nil
        }
        let reps = entries.map(\.repsText).joined(separator: ", ")
        return "\(WeightFormatter.string(weight)) \(unit.symbol) x \(reps)"
    }

    static func lastPerformanceSummary(
        exerciseID: String,
        logs: [WorkoutLog],
        programID: String,
        beforeDateKey: String,
        unit: WeightUnit
    ) -> String? {
        for log in previousLogs(logs, programID: programID, beforeDateKey: beforeDateKey) {
            guard let progress = log.setProgress.first(where: { $0.exerciseID == exerciseID }),
                  let summary = sessionSummary(for: progress, unit: unit) else { continue }
            return summary
        }
        return nil
    }

    /// The same set from the most recent earlier session, or that session's last logged set
    /// when today has more sets than last time. Returned in the requested unit.
    static func previousSetHint(
        exerciseID: String,
        setIndex: Int,
        logs: [WorkoutLog],
        programID: String,
        beforeDateKey: String,
        unit: WeightUnit
    ) -> SetEntry? {
        for log in previousLogs(logs, programID: programID, beforeDateKey: beforeDateKey) {
            guard let progress = log.setProgress.first(where: { $0.exerciseID == exerciseID }) else { continue }
            let entries = loggedEntries(in: progress)
            guard let source = entries.first(where: { $0.setIndex == setIndex }) ?? entries.last,
                  let weight = source.weight(in: unit) else { continue }
            return SetEntry(
                setIndex: setIndex,
                weightText: WeightFormatter.string(weight),
                repsText: source.repsText,
                unit: unit
            )
        }
        return nil
    }

    static func bestLifts(logs: [WorkoutLog], programID: String, unit: WeightUnit) -> [ExerciseRecord] {
        var best: [String: (pounds: Double, reps: Int)] = [:]
        for log in logs where log.programID == programID {
            for progress in log.setProgress {
                for entry in progress.setEntries where entry.isCompleted {
                    guard let pounds = entry.weight(in: .lb), let reps = entry.repsValue else { continue }
                    if let existing = best[progress.exerciseID] {
                        let heavier = pounds > existing.pounds + 0.001
                        let sameWeightMoreReps = abs(pounds - existing.pounds) <= 0.001 && reps > existing.reps
                        guard heavier || sameWeightMoreReps else { continue }
                    }
                    best[progress.exerciseID] = (pounds, reps)
                }
            }
        }
        return best
            .sorted { $0.key < $1.key }
            .map { ExerciseRecord(exerciseID: $0.key, weight: WeightUnit.lb.convert($0.value.pounds, to: unit), reps: $0.value.reps) }
    }

    private static func previousLogs(_ logs: [WorkoutLog], programID: String, beforeDateKey: String) -> [WorkoutLog] {
        logs
            .filter { $0.programID == programID && $0.dateKey < beforeDateKey }
            .sorted { $0.dateKey > $1.dateKey }
    }

    private static func loggedEntries(in progress: SetProgress) -> [SetEntry] {
        progress.setEntries
            .filter { $0.isCompleted && $0.hasLoggedValues }
            .sorted { $0.setIndex < $1.setIndex }
    }
}
