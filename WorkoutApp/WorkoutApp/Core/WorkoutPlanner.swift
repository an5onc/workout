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
