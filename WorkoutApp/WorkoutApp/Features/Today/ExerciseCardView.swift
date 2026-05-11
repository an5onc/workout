import SwiftUI

struct ExerciseCardView: View {
    let exercise: Exercise
    let isActive: Bool
    @Bindable var state: LocalAppState

    var body: some View {
        DisclosureGroup(isExpanded: .constant(isActive)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ForEach(0..<exercise.sets, id: \.self) { setIndex in
                        Button("Set \(setIndex + 1)") {
                            state.toggleSet(exerciseID: exercise.id, setIndex: setIndex)
                        }
                        .buttonStyle(.borderedProminent)
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
