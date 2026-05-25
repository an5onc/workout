import SwiftUI

struct PersonalizationFlowView: View {
    let state: LocalAppState
    let program: TrainingProgram
    let currentDate: () -> Date

    @Environment(\.dismiss) private var dismiss
    @State private var ageText = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var experienceLevel = "Some training"
    @State private var availableDays = 4
    @State private var limitations = ""
    @State private var pushUpRepsText = ""
    @State private var pushUpVariation: PushUpVariation = .standard
    @State private var stepCountText = ""
    @State private var recoveryHeartRateText = ""
    @State private var stepDifficulty = 6
    @State private var oneMileMinutesText = ""
    @State private var oneMileSecondsText = ""
    @State private var oneMileStyle: MileTestStyle = .walkRun
    @State private var oneMileDifficulty = 7

    init(state: LocalAppState, program: TrainingProgram, currentDate: @escaping () -> Date = Date.init) {
        self.state = state
        self.program = program
        self.currentDate = currentDate
    }

    private var profile: UserProfile? {
        guard let age = Int(ageText),
              let height = Int(heightText),
              let weight = Int(weightText),
              age > 0,
              height > 0,
              weight > 0 else {
            return nil
        }

        return UserProfile(
            age: age,
            heightInches: height,
            weightPounds: weight,
            experienceLevel: experienceLevel,
            availableWorkoutDaysPerWeek: availableDays,
            limitations: limitations
        )
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
            phase: .baseline,
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
        guard let profile, let assessment else {
            return nil
        }
        return PersonalizationCalculator.level(for: profile, assessment: assessment)
    }

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                assessmentInstructionsSection
                pushUpTestSection
                stepTestSection
                mileTestSection
                resultSection
            }
            .navigationTitle("Personalize plan")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var profileSection: some View {
        Section("Profile basics") {
            TextField("Age", text: $ageText)
                .keyboardType(.numberPad)
            TextField("Height in inches", text: $heightText)
                .keyboardType(.numberPad)
            TextField("Weight in pounds", text: $weightText)
                .keyboardType(.numberPad)
            Picker("Experience", selection: $experienceLevel) {
                Text("New to training").tag("New to training")
                Text("Some training").tag("Some training")
                Text("Consistent training").tag("Consistent training")
            }
            Stepper("Available days \(availableDays)/week", value: $availableDays, in: 2...6)
            TextField("Injuries or limitations", text: $limitations, axis: .vertical)
                .lineLimit(2...3)
        }
    }

    private var assessmentInstructionsSection: some View {
        Section("Baseline assessment") {
            Text("Complete these tests before starting the plan. Stop if form breaks, symptoms appear, or the effort no longer feels safe.")
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
                LabeledContent("Assigned level", value: levelPreview.title)
            } else {
                Text("Enter profile and assessment results to preview the assigned level.")
                    .foregroundStyle(.secondary)
            }

            Button("Finalize personalized plan") {
                finalize()
            }
            .disabled(profile == nil || assessment == nil)
        }
    }

    private func finalize() {
        guard let profile, let assessment else {
            return
        }

        state.finalizePersonalizedProgram(
            baseProgramID: program.id,
            profile: profile,
            assessment: assessment,
            startDate: currentDate()
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
