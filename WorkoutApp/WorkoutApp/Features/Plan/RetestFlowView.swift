import SwiftUI

struct RetestFlowView: View {
    let state: LocalAppState
    let program: TrainingProgram
    let phase: AssessmentPhase
    let currentDate: () -> Date

    @Environment(\.dismiss) private var dismiss
    @State private var pushUpRepsText = ""
    @State private var pushUpVariation: PushUpVariation = .standard
    @State private var stepCountText = ""
    @State private var recoveryHeartRateText = ""
    @State private var stepDifficulty = 6
    @State private var oneMileMinutesText = ""
    @State private var oneMileSecondsText = ""
    @State private var oneMileStyle: MileTestStyle = .walkRun
    @State private var oneMileDifficulty = 7

    init(
        state: LocalAppState,
        program: TrainingProgram,
        phase: AssessmentPhase,
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.state = state
        self.program = program
        self.phase = phase
        self.currentDate = currentDate
    }

    private var assessment: FitnessAssessment? {
        guard let pushUps = Int(pushUpRepsText),
              let steps = Int(stepCountText),
              let minutes = Int(oneMileMinutesText),
              let seconds = Int(oneMileSecondsText),
              pushUps >= 0,
              steps >= 0,
              minutes >= 0,
              seconds >= 0 else {
            return nil
        }

        let totalSeconds = (minutes * 60) + seconds
        guard totalSeconds > 0 else {
            return nil
        }

        return FitnessAssessment(
            dateKey: Self.dateKeyFormatter.string(from: currentDate()),
            phase: phase,
            pushUpReps: pushUps,
            pushUpVariation: pushUpVariation,
            stepTestDurationSeconds: 180,
            stepCount: steps,
            recoveryHeartRate: Int(recoveryHeartRateText),
            stepTestDifficulty: stepDifficulty,
            oneMileTimeSeconds: totalSeconds,
            oneMileStyle: oneMileStyle,
            oneMileDifficulty: oneMileDifficulty,
            computedLevel: .beginner
        )
    }

    private var levelPreview: TrainingLevel? {
        guard let profile = state.userProfile, let assessment else {
            return nil
        }
        return PersonalizationCalculator.level(for: profile, assessment: assessment)
    }

    var body: some View {
        NavigationStack {
            Form {
                instructionsSection
                pushUpTestSection
                stepTestSection
                mileTestSection
                resultSection
            }
            .navigationTitle("Record retest")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var instructionsSection: some View {
        Section(phase.title) {
            Text("Enter only the new test results. Your stored profile stays attached to the plan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var pushUpTestSection: some View {
        Section("Push-up test") {
            TextField("Push-ups before exhaustion", text: $pushUpRepsText)
                .keyboardType(.numberPad)
            Picker("Variation", selection: $pushUpVariation) {
                ForEach(PushUpVariation.allCases) { variation in
                    Text(variation.title).tag(variation)
                }
            }
        }
    }

    private var stepTestSection: some View {
        Section("Step test") {
            LabeledContent("Duration", value: "3 minutes")
            TextField("Total steps completed", text: $stepCountText)
                .keyboardType(.numberPad)
            TextField("1-minute recovery heart rate", text: $recoveryHeartRateText)
                .keyboardType(.numberPad)
            Stepper("Difficulty \(stepDifficulty)/10", value: $stepDifficulty, in: 1...10)
        }
    }

    private var mileTestSection: some View {
        Section("1-mile treadmill") {
            LabeledContent("Incline", value: "0.0")
            HStack {
                TextField("Minutes", text: $oneMileMinutesText)
                    .keyboardType(.numberPad)
                TextField("Seconds", text: $oneMileSecondsText)
                    .keyboardType(.numberPad)
            }
            Picker("Style", selection: $oneMileStyle) {
                ForEach(MileTestStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            Stepper("Difficulty \(oneMileDifficulty)/10", value: $oneMileDifficulty, in: 1...10)
        }
    }

    private var resultSection: some View {
        Section("Results") {
            if let levelPreview {
                LabeledContent("Updated level", value: levelPreview.title)
            } else {
                Text("Enter retest results to preview the updated level.")
                    .foregroundStyle(.secondary)
            }

            Button("Save retest") {
                save()
            }
            .disabled(assessment == nil || state.userProfile == nil)
        }
    }

    private func save() {
        guard let assessment else {
            return
        }

        state.recordFitnessRetest(
            baseProgramID: program.id,
            phase: phase,
            assessment: assessment,
            date: currentDate()
        )
        dismiss()
    }

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
