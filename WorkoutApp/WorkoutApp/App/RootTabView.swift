import SwiftUI

struct RootTabView: View {
    @Environment(LocalAppState.self) private var state

    var body: some View {
        TabView {
            TodayView(state: state)
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            ProgressDashboardView(state: state)
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            FoodView(state: state)
                .tabItem { Label("Food", systemImage: "fork.knife") }

            GroceryView(state: state)
                .tabItem { Label("Grocery", systemImage: "cart") }

            PlanView()
                .tabItem { Label("Plan", systemImage: "book") }
        }
        .tint(AppTheme.accent)
    }
}

struct ProgressDashboardView: View {
    let state: LocalAppState
    @State private var checkInDate = Date()

    private var recentWorkoutLogs: [WorkoutLog] {
        state.workoutLogs.sorted { $0.dateKey > $1.dateKey }.prefix(5).map { $0 }
    }

    private var checkIn: WeeklyCheckIn {
        state.weeklyCheckIn(for: checkInDate)
    }

    var body: some View {
        NavigationStack {
            List {
                performanceSection
                recordsSection
                weeklyCheckInSection
                compositionHistorySection
            }
            .navigationTitle("Progress")
        }
    }

    private var performanceSection: some View {
        Section("Recent training") {
            if recentWorkoutLogs.isEmpty {
                Text("Log sets in Today to start building workout history.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentWorkoutLogs) { log in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(log.dateKey)
                            .font(.headline)
                        Text("\(completedSetCount(in: log)) completed sets")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var recordsSection: some View {
        Section("Exercise records") {
            let records = exerciseRecords()
            if records.isEmpty {
                Text("Complete weighted sets to see best lifts here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records.prefix(8), id: \.exerciseID) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exerciseName(for: record.exerciseID))
                            .font(.headline)
                        Text("Best: \(record.weight) lb x \(record.reps)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var weeklyCheckInSection: some View {
        Section("Weekly check-in") {
            TextField("Body weight", text: checkInBinding(\.bodyWeightText))
                .keyboardType(.decimalPad)
            TextField("Waist", text: checkInBinding(\.waistText))
                .keyboardType(.decimalPad)
            TextField("Hips", text: checkInBinding(\.hipsText))
                .keyboardType(.decimalPad)

            Stepper("Energy \(checkIn.energy)/5", value: checkInIntBinding(\.energy), in: 1...5)
            Stepper("Soreness \(checkIn.soreness)/5", value: checkInIntBinding(\.soreness), in: 1...5)

            TextField("Notes", text: checkInBinding(\.notes), axis: .vertical)
                .lineLimit(2...4)
        }
    }

    private var compositionHistorySection: some View {
        Section("Body composition") {
            let checkIns = state.weeklyCheckIns.sorted { $0.dateKey > $1.dateKey }.prefix(6)
            if checkIns.isEmpty {
                Text("Weekly check-ins will appear here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(checkIns)) { checkIn in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(checkIn.dateKey)
                            .font(.headline)
                        Text("Weight \(display(checkIn.bodyWeightText)) | Waist \(display(checkIn.waistText)) | Hips \(display(checkIn.hipsText))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func checkInBinding(_ keyPath: WritableKeyPath<WeeklyCheckIn, String>) -> Binding<String> {
        Binding {
            checkIn[keyPath: keyPath]
        } set: { value in
            var updated = checkIn
            updated[keyPath: keyPath] = value
            save(updated)
        }
    }

    private func checkInIntBinding(_ keyPath: WritableKeyPath<WeeklyCheckIn, Int>) -> Binding<Int> {
        Binding {
            checkIn[keyPath: keyPath]
        } set: { value in
            var updated = checkIn
            updated[keyPath: keyPath] = value
            save(updated)
        }
    }

    private func save(_ checkIn: WeeklyCheckIn) {
        state.updateWeeklyCheckIn(
            date: checkInDate,
            bodyWeightText: checkIn.bodyWeightText,
            waistText: checkIn.waistText,
            hipsText: checkIn.hipsText,
            energy: checkIn.energy,
            soreness: checkIn.soreness,
            notes: checkIn.notes
        )
    }

    private func completedSetCount(in log: WorkoutLog) -> Int {
        log.setProgress.reduce(0) { total, progress in
            total + progress.setEntries.filter(\.isCompleted).count
        }
    }

    private func exerciseRecords() -> [(exerciseID: String, weight: String, reps: String)] {
        var records: [String: (weight: Double, reps: Int)] = [:]
        for log in state.workoutLogs {
            for progress in log.setProgress {
                for entry in progress.setEntries where entry.isCompleted {
                    guard let weight = Double(entry.weightText), let reps = Int(entry.repsText) else { continue }
                    let existing = records[progress.exerciseID]
                    if existing == nil || weight > existing!.weight || (weight == existing!.weight && reps > existing!.reps) {
                        records[progress.exerciseID] = (weight, reps)
                    }
                }
            }
        }
        return records
            .sorted { $0.key < $1.key }
            .map { (exerciseID: $0.key, weight: formatWeight($0.value.weight), reps: "\($0.value.reps)") }
    }

    private func exerciseName(for exerciseID: String) -> String {
        ProgramSeed.weeklySchedule
            .flatMap(\.exercises)
            .first { $0.id == exerciseID }?
            .name ?? exerciseID
    }

    private func formatWeight(_ weight: Double) -> String {
        weight.rounded() == weight ? String(Int(weight)) : String(format: "%.1f", weight)
    }

    private func display(_ value: String) -> String {
        value.isEmpty ? "--" : value
    }
}
