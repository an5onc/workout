import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    @Binding var isExpanded: Bool
    let state: LocalAppState

    private let setColumns = [
        GridItem(.adaptive(minimum: 96), spacing: 8)
    ]

    var body: some View {
        let completedSets = state.progress(for: exercise.id).completedSets

        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: setColumns, alignment: .leading, spacing: 8) {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        let isCompleted = completedSets.contains(setIndex)

                        Button {
                            state.toggleSet(exerciseID: exercise.id, setIndex: setIndex)
                        } label: {
                            Text(isCompleted ? "✓ Set \(setIndex + 1)" : "Set \(setIndex + 1)")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                        }
                        .foregroundStyle(isCompleted ? .white : AppTheme.accent)
                        .background(isCompleted ? AppTheme.accent : AppTheme.accentSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel("Set \(setIndex + 1)")
                        .accessibilityValue(isCompleted ? "Completed" : "Not completed")
                        .accessibilityHint("Toggles set completion")
                    }
                }

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
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name).font(.headline)
                Text("\(exercise.sets) x \(exercise.repRange) | rest \(exercise.rest)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
