import SwiftUI

struct TodayView: View {
    @Bindable var state: LocalAppState
    @State private var manuallyExpandedExerciseIDs: Set<String> = []
    @State private var manuallyCollapsedExerciseIDs: Set<String> = []
    private let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let workout = planner.workout(for: currentWeekday(), override: state.selectedDayOverride) ?? ProgramSeed.weeklySchedule[1]
                    header(for: workout)

                    if workout.isRestDay {
                        restCard(for: workout)
                    } else {
                        let active = planner.activeExercise(in: workout, progress: state.setProgress)
                        ForEach(workout.exercises) { exercise in
                            ExerciseCardView(
                                exercise: exercise,
                                isExpanded: expansionBinding(for: exercise, activeExerciseID: active?.id),
                                state: state
                            )
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.cream)
            .navigationTitle("Today")
        }
    }

    private func header(for workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.focus.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text(workout.name)
                .font(.largeTitle.bold())
            Text(workout.subtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func restCard(for workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recovery day").font(.title2.bold())
            Text(workout.subtitle)
            Text("Recovery is when the body rebuilds. Today is part of the plan.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func expansionBinding(for exercise: Exercise, activeExerciseID: String?) -> Binding<Bool> {
        Binding {
            if manuallyCollapsedExerciseIDs.contains(exercise.id) {
                return false
            }
            return exercise.id == activeExerciseID || manuallyExpandedExerciseIDs.contains(exercise.id)
        } set: { isExpanded in
            if isExpanded {
                manuallyExpandedExerciseIDs.insert(exercise.id)
                manuallyCollapsedExerciseIDs.remove(exercise.id)
            } else {
                manuallyExpandedExerciseIDs.remove(exercise.id)
                manuallyCollapsedExerciseIDs.insert(exercise.id)
            }
        }
    }

    private func currentWeekday() -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday.allCases[weekday - 1]
    }
}
