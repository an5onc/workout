import SwiftUI

struct TodayView: View {
    let state: LocalAppState
    @State private var manuallyExpandedExerciseIDs: Set<String> = []
    @State private var manuallyCollapsedExerciseIDs: Set<String> = []
    @State private var lastActiveExerciseID: String?
    private let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let workout = planner.workout(for: currentWeekday(), override: state.selectedDayOverride) ?? ProgramSeed.weeklySchedule[1]
                    brandBanner
                    header(for: workout)

                    if workout.isRestDay {
                        restCard(for: workout)
                    } else {
                        let active = planner.activeExercise(in: workout, progress: state.setProgress)
                        Group {
                            ForEach(workout.exercises) { exercise in
                                ExerciseCardView(
                                    exercise: exercise,
                                    isExpanded: expansionBinding(for: exercise, activeExerciseID: active?.id),
                                    state: state
                                )
                            }
                            finishSummary(for: workout)
                        }
                        .onAppear {
                            updateActiveExercise(active?.id)
                        }
                        .onChange(of: active?.id) { _, newActiveExerciseID in
                            updateActiveExercise(newActiveExerciseID)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.cream)
            .navigationTitle("Today")
        }
    }

    private var brandBanner: some View {
        Image("BrandWordmark")
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color(red: 0.118, green: 0.118, blue: 0.11))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityLabel("I'd Lift That")
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

    private func finishSummary(for workout: WorkoutDay) -> some View {
        let log = state.workoutLog(for: Date())
        let summary = WorkoutPlanner.summary(for: workout, log: log)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.isFinished ? "Workout finished" : "Finish workout")
                        .font(.headline)
                    Text("\(summary.completedSets)/\(summary.totalSets) sets | \(formatVolume(summary.totalVolume)) lb volume")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: summary.isFinished ? "checkmark.seal.fill" : "flag.checkered")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }

            if summary.remainingSets > 0 {
                Text("\(summary.remainingSets) sets left if she wants the full plan today.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("All planned sets are checked off.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                state.finishWorkout(date: Date())
            } label: {
                Label(summary.isFinished ? "Finished" : "Mark workout finished", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(summary.isFinished)
        }
        .padding()
        .background(.background)
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

    private func updateActiveExercise(_ activeExerciseID: String?) {
        guard activeExerciseID != lastActiveExerciseID else { return }
        lastActiveExerciseID = activeExerciseID
        if let activeExerciseID {
            manuallyCollapsedExerciseIDs.remove(activeExerciseID)
        }
    }

    private func currentWeekday() -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday.allCases[weekday - 1]
    }

    private func formatVolume(_ volume: Double) -> String {
        volume.rounded() == volume ? String(Int(volume)) : String(format: "%.1f", volume)
    }
}
