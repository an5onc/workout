import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    @Binding var isExpanded: Bool
    let state: LocalAppState
    var currentDate: () -> Date = Date.init

    @State private var remainingRestSeconds = 0
    @State private var isRestTimerRunning = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        let progress = state.progress(for: exercise.id)
        let completedSets = progress.completedSets

        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                performanceContext(progress: progress)
                substitutionSection

                VStack(spacing: 8) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        let isCompleted = completedSets.contains(setIndex)

                        HStack(spacing: 8) {
                            Text("Set \(setIndex + 1)")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 48, alignment: .leading)

                            TextField("lb", text: weightBinding(for: setIndex))
                                .keyboardType(.decimalPad)
                                .workoutTextField()

                            TextField("reps", text: repsBinding(for: setIndex))
                                .keyboardType(.numberPad)
                                .workoutTextField()

                            Button {
                                state.toggleSet(exerciseID: exercise.id, setIndex: setIndex, date: currentDate())
                                if !isCompleted {
                                    startRestTimer()
                                }
                            } label: {
                                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                            }
                            .accessibilityLabel("Set \(setIndex + 1)")
                            .accessibilityValue(isCompleted ? "Completed" : "Not completed")
                            .accessibilityHint("Toggles set completion")
                        }
                    }
                }

                restTimerControl

                if let demoURL = exercise.demoURL {
                    Link(destination: demoURL) {
                        Label("Demo", systemImage: "play.rectangle")
                    }
                    .font(.headline)
                } else {
                    Label("Demo coming soon", systemImage: "play.slash")
                        .foregroundStyle(.secondary)
                }

                Text("Cue: \(exercise.cue)").font(.subheadline)
                Text(exercise.feel).font(.footnote).foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .onReceive(timer) { _ in
                guard isRestTimerRunning else { return }
                if remainingRestSeconds > 0 {
                    remainingRestSeconds -= 1
                } else {
                    isRestTimerRunning = false
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name).font(.headline)
                Text("\(exercise.sets) x \(exercise.repRange) | rest \(exercise.rest)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func performanceContext(progress: SetProgress) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let last = state.lastPerformanceSummary(exerciseID: exercise.id, before: currentDate()) {
                Text("Last time: \(last)")
                    .font(.subheadline.weight(.semibold))
            } else {
                Text("Last time: no logged sets yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(WorkoutProgressAdvisor.suggestion(for: exercise, progress: progress))
                .font(.footnote)
                .foregroundStyle(AppTheme.accent)
        }
    }

    @ViewBuilder
    private var substitutionSection: some View {
        if !exercise.substitutions.isEmpty {
            let selectedID = state.selectedSubstitutionID(exerciseID: exercise.id, date: currentDate())
            let selected = exercise.substitutions.first { $0.id == selectedID }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Machine taken?", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Menu {
                        Button("Use planned exercise") {
                            state.selectSubstitution(exerciseID: exercise.id, substitutionID: nil, date: currentDate())
                        }

                        ForEach(exercise.substitutions) { substitution in
                            Button(substitution.name) {
                                state.selectSubstitution(exerciseID: exercise.id, substitutionID: substitution.id, date: currentDate())
                            }
                        }
                    } label: {
                        Label(selected == nil ? "Swap" : "Change", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(.bordered)
                }

                if let selected {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selected.name)
                            .font(.headline)
                        Text("\(selected.equipment) | \(selected.target)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(selected.cue)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        if let demoURL = selected.demoURL {
                            Link(destination: demoURL) {
                                Label("Sub demo", systemImage: "play.rectangle")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.elevatedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Text(exercise.substitutions.map(\.name).joined(separator: " | "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var restTimerControl: some View {
        HStack {
            Label(restTimerLabel, systemImage: "timer")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button(isRestTimerRunning ? "Pause" : "Start") {
                if remainingRestSeconds == 0 {
                    remainingRestSeconds = restSeconds
                }
                isRestTimerRunning.toggle()
            }
            .buttonStyle(.bordered)

            Button("Reset") {
                remainingRestSeconds = restSeconds
                isRestTimerRunning = false
            }
            .buttonStyle(.bordered)
        }
    }

    private var restTimerLabel: String {
        guard remainingRestSeconds > 0 else {
            return "Rest \(exercise.rest)"
        }
        return "\(remainingRestSeconds / 60):\(String(format: "%02d", remainingRestSeconds % 60))"
    }

    private var restSeconds: Int {
        let matches = exercise.rest.matches(of: /\d+/)
        guard let first = matches.first, let value = Int(first.output) else {
            return 60
        }
        return exercise.rest.localizedCaseInsensitiveContains("minute") ? value * 60 : value
    }

    private func startRestTimer() {
        remainingRestSeconds = restSeconds
        isRestTimerRunning = true
    }

    private func weightBinding(for setIndex: Int) -> Binding<String> {
        Binding {
            state.setEntry(exerciseID: exercise.id, setIndex: setIndex).weightText
        } set: { newValue in
            let entry = state.setEntry(exerciseID: exercise.id, setIndex: setIndex)
            state.updateSetEntry(exerciseID: exercise.id, setIndex: setIndex, weightText: newValue, repsText: entry.repsText, date: currentDate())
        }
    }

    private func repsBinding(for setIndex: Int) -> Binding<String> {
        Binding {
            state.setEntry(exerciseID: exercise.id, setIndex: setIndex).repsText
        } set: { newValue in
            let entry = state.setEntry(exerciseID: exercise.id, setIndex: setIndex)
            state.updateSetEntry(exerciseID: exercise.id, setIndex: setIndex, weightText: entry.weightText, repsText: newValue, date: currentDate())
        }
    }
}

private struct WorkoutTextFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.subheadline)
            .foregroundStyle(.primary)
            .tint(AppTheme.accent)
            .padding(.horizontal, 8)
            .frame(height: 34)
            .background(AppTheme.elevatedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(.secondary.opacity(0.24), lineWidth: 1)
            }
    }
}

private extension View {
    func workoutTextField() -> some View {
        modifier(WorkoutTextFieldModifier())
    }
}
