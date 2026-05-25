import Foundation

struct ProgressAdherence: Hashable {
    let completedTrainingDays: Int
    let plannedTrainingDays: Int
    let completedCardioDays: Int
    let plannedCardioDays: Int
}

enum ProgressMetricsCalculator {
    static func change(in checkIns: [WeeklyCheckIn], value: KeyPath<WeeklyCheckIn, String>) -> Double? {
        let values = checkIns
            .sorted { $0.dateKey < $1.dateKey }
            .compactMap { checkIn -> (dateKey: String, value: Double)? in
                guard let number = Double(checkIn[keyPath: value]) else {
                    return nil
                }
                return (dateKey: checkIn.dateKey, value: number)
            }

        guard let first = values.first, let last = values.last, first.dateKey != last.dateKey else {
            return nil
        }

        return last.value - first.value
    }

    static func weeklyAdherence(
        program: TrainingProgram,
        workoutLogs: [WorkoutLog],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ProgressAdherence {
        let completedLogKeys = Set(
            workoutLogs
                .filter { $0.programID == program.id && $0.finishedAt != nil }
                .map(\.dateKey)
        )

        let recentDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: referenceDate)
        }

        var plannedTrainingDays = 0
        var completedTrainingDays = 0
        var plannedCardioDays = 0
        var completedCardioDays = 0

        for date in recentDays {
            let weekdayIndex = calendar.component(.weekday, from: date) - 1
            let weekday = Weekday.allCases[weekdayIndex]
            guard let workout = program.weeklySchedule.first(where: { $0.id == weekday }), !workout.isRestDay else {
                continue
            }

            let key = dateKey(for: date, calendar: calendar)
            let isCompleted = completedLogKeys.contains(key)
            plannedTrainingDays += 1
            if isCompleted {
                completedTrainingDays += 1
            }

            if isWalkingOrCardioDay(workout) {
                plannedCardioDays += 1
                if isCompleted {
                    completedCardioDays += 1
                }
            }
        }

        return ProgressAdherence(
            completedTrainingDays: completedTrainingDays,
            plannedTrainingDays: plannedTrainingDays,
            completedCardioDays: completedCardioDays,
            plannedCardioDays: plannedCardioDays
        )
    }

    private static func isWalkingOrCardioDay(_ workout: WorkoutDay) -> Bool {
        let searchable = ([workout.focus, workout.subtitle] + workout.exercises.map(\.name))
            .joined(separator: " ")
            .lowercased()
        return searchable.contains("conditioning")
            || searchable.contains("walk")
            || searchable.contains("bike")
            || searchable.contains("elliptical")
            || searchable.contains("cardio")
            || searchable.contains("treadmill")
    }

    private static func dateKey(for date: Date, calendar: Calendar) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
