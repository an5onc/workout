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
                adherenceSection
                performanceSection
                exerciseHistorySection
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
                    let workout = workoutForLog(log)
                    let summary = workout.map { WorkoutPlanner.summary(for: $0, log: log) }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(log.dateKey)
                                .font(.headline)
                            Spacer()
                            if log.finishedAt != nil {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        Text(summaryText(for: summary, fallbackLog: log))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var adherenceSection: some View {
        Section("Weekly adherence") {
            ForEach(recentScheduleDays(), id: \.dateKey) { day in
                HStack(spacing: 12) {
                    Image(systemName: day.isFinished ? "checkmark.circle.fill" : day.completedSets > 0 ? "circle.lefthalf.filled" : "circle")
                        .foregroundStyle(day.isFinished ? AppTheme.accent : .secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(day.title)
                            .font(.headline)
                        Text("\(day.dateKey) | \(day.completedSets) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private var exerciseHistorySection: some View {
        Section("Exercise history") {
            let records = exerciseRecords()
            if records.isEmpty {
                Text("Complete weighted sets to see best lifts here.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records.prefix(8), id: \.exerciseID) { record in
                    DisclosureGroup {
                        let sessions = exerciseSessions(for: record.exerciseID)
                        if sessions.isEmpty {
                            Text("No session details yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(sessions.prefix(4), id: \.dateKey) { session in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(session.dateKey)
                                        .font(.subheadline.weight(.semibold))
                                    Text(session.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    } label: {
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

    private func exerciseSessions(for exerciseID: String) -> [(dateKey: String, summary: String)] {
        state.workoutLogs
            .sorted { $0.dateKey > $1.dateKey }
            .compactMap { log in
                guard let progress = log.setProgress.first(where: { $0.exerciseID == exerciseID }) else {
                    return nil
                }
                let entries = progress.setEntries
                    .filter { $0.isCompleted && !$0.weightText.isEmpty && !$0.repsText.isEmpty }
                    .sorted { $0.setIndex < $1.setIndex }
                guard !entries.isEmpty else { return nil }
                let firstWeight = entries.first?.weightText ?? ""
                let reps = entries.map(\.repsText).joined(separator: ", ")
                return (dateKey: log.dateKey, summary: "\(firstWeight) lb x \(reps)")
            }
    }

    private func recentScheduleDays() -> [(dateKey: String, title: String, completedSets: Int, isFinished: Bool)] {
        recentDateKeys(limit: 7).map { dateKey in
            let log = state.workoutLogs.first { $0.dateKey == dateKey } ?? WorkoutLog(dateKey: dateKey)
            return (
                dateKey: dateKey,
                title: workoutForLog(log)?.name ?? "Workout",
                completedSets: completedSetCount(in: log),
                isFinished: log.finishedAt != nil
            )
        }
    }

    private func recentDateKeys(limit: Int) -> [String] {
        let calendar = Calendar.current
        return (0..<limit).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: Date()).map { Self.dateKeyFormatter.string(from: $0) }
        }
    }

    private func workoutForLog(_ log: WorkoutLog) -> WorkoutDay? {
        guard let date = Self.dateKeyFormatter.date(from: log.dateKey) else {
            return nil
        }
        let weekday = Calendar.current.component(.weekday, from: date)
        return ProgramSeed.workout(for: Weekday.allCases[weekday - 1])
    }

    private func summaryText(for summary: WorkoutSummary?, fallbackLog log: WorkoutLog) -> String {
        guard let summary else {
            return "\(completedSetCount(in: log)) completed sets"
        }
        return "\(summary.completedSets)/\(summary.totalSets) sets | \(formatWeight(summary.totalVolume)) lb volume"
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

    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
