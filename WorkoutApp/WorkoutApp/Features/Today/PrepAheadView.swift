import SwiftUI

struct PrepAheadView: View {
    let workout: WorkoutDay
    let futureDate: Date
    let state: LocalAppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if workout.isRestDay {
                restPreview
            } else {
                ForEach(workout.exercises) { exercise in
                    PrepAheadExerciseCard(exercise: exercise, futureDate: futureDate, state: state)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Prep Ahead")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text("\(Self.dateFormatter.string(from: futureDate)) | \(workout.name)")
                .font(.headline)
            Text(workout.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var restPreview: some View {
        Text("Recovery day. Review meal prep, walking, and sleep instead of lifting.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()
}

private struct PrepAheadExerciseCard: View {
    let exercise: Exercise
    let futureDate: Date
    let state: LocalAppState

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                Text("Cue: \(exercise.cue)")
                    .font(.subheadline)
                Text(exercise.feel)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                demoLink
                substitutionMenu
            }
            .padding(.top, 6)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.subheadline.weight(.semibold))
                Text("\(exercise.sets) x \(exercise.repRange) | rest \(exercise.rest)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(AppTheme.elevatedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var demoLink: some View {
        if let demoURL = exercise.demoURL {
            Link(destination: demoURL) {
                Label("Demo", systemImage: "play.rectangle")
            }
            .font(.subheadline.weight(.semibold))
        } else {
            Label("Demo coming soon", systemImage: "play.slash")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var substitutionMenu: some View {
        if exercise.substitutions.isEmpty {
            Text("No substitutions listed.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            let selectedID = state.selectedSubstitutionID(exerciseID: exercise.id, date: futureDate)
            let selected = exercise.substitutions.first { $0.id == selectedID }

            VStack(alignment: .leading, spacing: 6) {
                Menu {
                    Button("Use planned exercise") {
                        state.selectSubstitution(exerciseID: exercise.id, substitutionID: nil, date: futureDate)
                    }

                    ForEach(exercise.substitutions) { substitution in
                        Button(substitution.name) {
                            state.selectSubstitution(exerciseID: exercise.id, substitutionID: substitution.id, date: futureDate)
                        }
                    }
                } label: {
                    Label(selected == nil ? "Plan substitution" : "Change substitution", systemImage: "slider.horizontal.3")
                }
                .buttonStyle(.bordered)

                Text(selected?.name ?? "Planned exercise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
