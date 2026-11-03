import SwiftUI

struct TodayView: View {
    let state: LocalAppState
    let currentDate: () -> Date

    init(state: LocalAppState, currentDate: @escaping () -> Date = Date.init) {
        self.state = state
        self.currentDate = currentDate
    }

    @State private var selectedPrepAheadOffset = 1
    @State private var manuallyExpandedExerciseIDs: Set<String> = []
    @State private var manuallyCollapsedExerciseIDs: Set<String> = []
    @State private var lastActiveExerciseID: String?
    @Environment(\.scenePhase) private var scenePhase

    private var selectedProgram: TrainingProgram {
        state.selectedProgram
    }

    private var planner: WorkoutPlanner {
        WorkoutPlanner(schedule: state.selectedProgram.weeklySchedule)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let workout = state.scheduledWorkout(on: currentDate()) ?? selectedProgram.weeklySchedule[1]
                    retestPromptSection
                    planSummaryCard
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
                                    state: state,
                                    currentDate: currentDate
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

                    prepAheadSection
                }
                .padding()
            }
            .background(AppTheme.screenBackground)
            .navigationTitle("Today")
            .onAppear { state.prepareDay(currentDate()) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    state.prepareDay(currentDate())
                }
            }
        }
    }

    private var planSummaryCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "target")
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 3) {
                Text(selectedProgram.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(selectedProgram.goal) | \(activeTrainingDays(in: selectedProgram)) training days | \(selectedProgram.nutritionTargets.proteinGrams)g protein")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let personalizedProgram = currentPersonalizedProgram {
                    Text("Training level: \(personalizedProgram.assignedLevel.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var retestPromptSection: some View {
        if let personalizedProgram = currentPersonalizedProgram,
           let phase = PersonalizationCalculator.nextRetestPhase(
            program: personalizedProgram,
            assessments: state.fitnessAssessments,
            on: currentDate()
           ) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "stopwatch.fill")
                    .foregroundStyle(AppTheme.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Retest due")
                        .font(.headline)
                    Text("\(phase.title) assessment is ready: push-ups, 3-minute step test, and 1-mile treadmill at 0.0 incline.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Open Plan to record the retest and adjust the next block.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(AppTheme.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var prepAheadSection: some View {
        let futureDate = prepAheadDate(offset: selectedPrepAheadOffset)
        let futureWorkout = state.scheduledWorkout(on: futureDate) ?? selectedProgram.weeklySchedule[1]

        return VStack(alignment: .leading, spacing: 10) {
            Text("Prep ahead")
                .font(.title3.bold())
                .padding(.top, 8)
            HStack {
                Text("Choose day")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("+\(selectedPrepAheadOffset)d")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { offset in
                        prepAheadOffsetButton(offset: offset)
                    }
                }
            }

            PrepAheadView(workout: futureWorkout, futureDate: futureDate, state: state)
        }
    }

    @ViewBuilder
    private func prepAheadOffsetButton(offset: Int) -> some View {
        let isSelected = offset == selectedPrepAheadOffset
        let accessibilityLabel = offset == 1 ? "1 day ahead" : "\(offset) days ahead"
        let label = Text("+\(offset)")
            .font(.subheadline.weight(.semibold))
            .frame(width: 44, height: 34)

        if isSelected {
            Button {
                selectedPrepAheadOffset = offset
            } label: {
                label
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue("Selected")
            .accessibilityAddTraits(.isSelected)
        } else {
            Button {
                selectedPrepAheadOffset = offset
            } label: {
                label
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue("Not selected")
        }
    }

    private func prepAheadDate(offset: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: currentDate()) ?? currentDate()
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
            workoutSwapMenu(current: workout)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func workoutSwapMenu(current workout: WorkoutDay) -> some View {
        let today = currentDate()
        let normalDay = LocalAppState.weekday(for: today)
        let isSwapped = state.workoutDayOverride(on: today) != nil

        return Menu {
            if isSwapped {
                Button("Back to today's planned workout") {
                    state.setWorkoutDayOverride(nil, date: today)
                }
            }
            ForEach(selectedProgram.weeklySchedule.filter { !$0.isRestDay && $0.id != workout.id }) { day in
                Button("\(day.name) (\(day.id.rawValue.capitalized))") {
                    state.setWorkoutDayOverride(day.id == normalDay ? nil : day.id, date: today)
                }
            }
        } label: {
            Label(isSwapped ? "Swapped for today. Change" : "Doing a different workout today?", systemImage: "arrow.left.arrow.right")
                .font(.footnote.weight(.semibold))
        }
        .tint(AppTheme.accent)
    }

    private func finishSummary(for workout: WorkoutDay) -> some View {
        let log = state.workoutLog(for: currentDate())
        let summary = WorkoutPlanner.summary(for: workout, log: log, unit: state.weightUnit)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(summary.isFinished ? "Workout finished" : "Finish workout")
                        .font(.headline)
                    Text("\(summary.completedSets)/\(summary.totalSets) sets | \(formatVolume(summary.totalVolume)) \(state.weightUnit.symbol) volume")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: summary.isFinished ? "checkmark.seal.fill" : "flag.checkered")
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
            }

            if summary.remainingSets > 0 {
                Text("\(summary.remainingSets) sets left for the full plan today.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("All planned sets are checked off.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Button {
                state.finishWorkout(date: currentDate())
            } label: {
                Label(summary.isFinished ? "Finished" : "Mark workout finished", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(summary.isFinished)
        }
        .padding()
        .background(AppTheme.cardBackground)
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
        .background(AppTheme.cardBackground)
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

    private func activeTrainingDays(in program: TrainingProgram) -> Int {
        program.weeklySchedule.filter { !$0.isRestDay }.count
    }

    private var currentPersonalizedProgram: PersonalizedProgram? {
        state.personalizedPrograms.first { $0.baseProgramID == state.selectedProgramID }
    }

    private func formatVolume(_ volume: Double) -> String {
        volume.rounded() == volume ? String(Int(volume)) : String(format: "%.1f", volume)
    }
}
