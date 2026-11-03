import SwiftUI

struct PlanView: View {
    let state: LocalAppState
    @State private var exerciseSearchText = ""
    @State private var pendingProgramSelection: TrainingProgram?
    @State private var personalizationProgram: TrainingProgram?
    @State private var retestContext: RetestContext?
    @State private var previewProgramID = ProgramSeed.defaultProgramID

    private var selectedProgram: TrainingProgram {
        state.selectedProgram
    }

    private var selectedProgramPreview: TrainingProgram {
        ProgramSeed.program(id: previewProgramID) ?? selectedProgram
    }

    private var filteredExercises: [Exercise] {
        let exercises = exerciseLibrary
        let query = exerciseSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return exercises
        }

        return exercises.filter { exercise in
            exercise.name.localizedCaseInsensitiveContains(query)
                || exercise.cue.localizedCaseInsensitiveContains(query)
                || exercise.repRange.localizedCaseInsensitiveContains(query)
        }
    }

    private var exerciseLibrary: [Exercise] {
        var seenIDs = Set<String>()

        return state.selectedProgram.weeklySchedule
            .flatMap(\.exercises)
            .filter { exercise in
                seenIDs.insert(exercise.id).inserted
            }
            .sorted { $0.name < $1.name }
    }

    private var groceryReferenceSections: [GrocerySection] {
        GroceryListGenerator.generate(from: selectedProgram.mealTemplates)
    }

    private var unitsSection: some View {
        Section {
            Picker("Weight unit", selection: Binding(
                get: { state.weightUnit },
                set: { state.weightUnit = $0 }
            )) {
                ForEach(WeightUnit.allCases) { unit in
                    Text(unit.symbol).tag(unit)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Units")
        } footer: {
            Text("Past sets keep the unit they were logged in and are converted for display.")
        }
    }

    var body: some View {
        NavigationStack {
            List {
                programGoalOverviewSection
                adaptiveExplanationSection
                programSelectionSection
                unitsSection
                structureSection
                weeklyScheduleSection
                exerciseLibrarySection
                nutritionReferenceSection
                groceryReferenceSection
                sundayPrepSection
            }
            .navigationTitle("Plan")
            .searchable(text: $exerciseSearchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search exercises")
            .confirmationDialog(
                "Switch plans",
                isPresented: Binding(
                    get: { pendingProgramSelection != nil },
                    set: { isPresented in
                        if !isPresented {
                            pendingProgramSelection = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                if let program = pendingProgramSelection {
                    Button("Switch plans") {
                        state.selectProgram(id: program.id)
                        pendingProgramSelection = nil
                    }
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Switching plans resets Grocery picks so old meal selections do not carry into the new plan.")
            }
            .sheet(item: $personalizationProgram) { program in
                PersonalizationFlowView(state: state, program: program)
            }
            .sheet(item: $retestContext) { context in
                RetestFlowView(state: state, program: context.program, phase: context.phase)
            }
        }
    }

    private var adaptiveExplanations: [String] {
        guard let profile = state.userProfile,
              let personalizedProgram = state.personalizedPrograms.first(where: { $0.baseProgramID == state.selectedProgramID }),
              let latestAssessment = state.fitnessAssessments.first(where: { $0.id == personalizedProgram.latestAssessmentID }) else {
            return []
        }

        return PersonalizationCalculator.adaptiveExplanations(for: profile, assessment: latestAssessment)
    }

    private var programSelectionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Text("Current plan")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text(state.selectedProgram.name)
                    .font(.title3.weight(.bold))
                Text(selectedProgram.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            ForEach(ProgramSeed.programs) { program in
                programOptionRow(program)
            }

            Text("Switching plans resets Grocery picks so old meal selections do not carry into the new plan.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var programGoalOverviewSection: some View {
        Section("Choose your goal") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ProgramSeed.programs) { program in
                        goalCard(program)
                    }
                }
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Plan preview")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text(selectedProgramPreview.name)
                    .font(.headline)
                Text(selectedProgramPreview.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack {
                    metricPill("\(selectedProgramPreview.nutritionTargets.calories)", "cal")
                    metricPill("\(selectedProgramPreview.nutritionTargets.proteinGrams)g", "protein")
                    metricPill("\(activeTrainingDays(in: selectedProgramPreview))", "training days")
                }

                Button("Personalize plan") {
                    personalizationProgram = selectedProgramPreview
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)

                if let phase = retestPhase(for: selectedProgramPreview) {
                    Button("Record retest") {
                        retestContext = RetestContext(program: selectedProgramPreview, phase: phase)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                }
            }
            .padding(.vertical, 4)
        }
        .onAppear {
            previewProgramID = state.selectedProgram.id
        }
        .onChange(of: state.selectedProgram.id) { _, newProgramID in
            previewProgramID = newProgramID
        }
    }

    private var adaptiveExplanationSection: some View {
        let explanations = adaptiveExplanations

        return Section("Why these exercises") {
            if explanations.isEmpty {
                Text("Personalize a plan to see how the assessment changes exercise choices.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(explanations, id: \.self) { explanation in
                    Label(explanation, systemImage: "target")
                        .font(.subheadline)
                }
            }
        }
    }

    private func goalCard(_ program: TrainingProgram) -> some View {
        let isPreviewed = program.id == selectedProgramPreview.id
        let isCurrent = program.id == state.selectedProgram.id

        return Button {
            previewProgramID = program.id
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(program.goal)
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isCurrent ? AppTheme.accent : .secondary)
                }
                Text(program.name)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(program.weeklyStructure.first ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(width: 180, alignment: .topLeading)
            .frame(minHeight: 104, alignment: .topLeading)
            .padding(12)
            .background(isPreviewed ? AppTheme.accentSoft : AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(program.goal), \(program.name)")
        .accessibilityValue(isPreviewed ? "Previewed" : "Not previewed")
    }

    private func programOptionRow(_ program: TrainingProgram) -> some View {
        let isCurrent = program.id == state.selectedProgram.id

        return HStack(alignment: .center, spacing: 12) {
            Image(systemName: isCurrent ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCurrent ? AppTheme.accent : .secondary)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(program.name)
                    .font(.headline)
                Text(program.goal)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
                Text(program.weeklyStructure.joined(separator: " / "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Button(isCurrent ? "Current" : "Use this plan") {
                pendingProgramSelection = program
            }
            .buttonStyle(.bordered)
            .tint(isCurrent ? .secondary : AppTheme.accent)
            .controlSize(.small)
            .disabled(isCurrent)
        }
        .padding(.vertical, 4)
    }

    private var structureSection: some View {
        Section("12-week structure") {
            ForEach(selectedProgram.weeklyStructure, id: \.self) { item in
                Text(item)
                    .font(.subheadline)
                    .padding(.vertical, 3)
            }
        }
    }

    private var weeklyScheduleSection: some View {
        Section("Weekly schedule") {
            ForEach(state.selectedProgram.weeklySchedule) { day in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(weekdayTitle(day.id))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                        Spacer()
                        Text(day.isRestDay ? "Rest" : "\(day.exercises.count) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(day.name)
                        .font(.headline)

                    Text(day.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 3)
            }
        }
    }

    private var exerciseLibrarySection: some View {
        Section("Exercise library") {
            if filteredExercises.isEmpty {
                Text("No exercises match this search.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredExercises) { exercise in
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 8) {
                            LabeledContent("Sets", value: "\(exercise.sets)")
                            LabeledContent("Reps", value: exercise.repRange)
                            LabeledContent("Rest", value: exercise.rest)

                            Text(exercise.cue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if let demoURL = exercise.demoURL {
                                Link("Demo", destination: demoURL)
                            }
                        }
                        .padding(.vertical, 6)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name)
                                .font(.headline)
                            Text("\(exercise.sets) sets | \(exercise.repRange) | \(exercise.rest)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var nutritionReferenceSection: some View {
        Section("Nutrition reference") {
            LabeledContent("Calories", value: "\(selectedProgram.nutritionTargets.calories)")
            LabeledContent("Protein", value: "\(state.selectedProgram.nutritionTargets.proteinGrams)g")
            LabeledContent("Fat", value: "\(selectedProgram.nutritionTargets.fatGrams)g")
            LabeledContent("Carbs", value: "\(selectedProgram.nutritionTargets.carbsGrams)g")
            LabeledContent("Water", value: "\(selectedProgram.nutritionTargets.waterOunces) oz")

            ForEach(selectedProgram.mealTemplates) { meal in
                VStack(alignment: .leading, spacing: 4) {
                    Text(meal.name)
                        .font(.headline)
                    Text("\(meal.calories) cal | \(meal.proteinGrams)g protein | \(mealKindTitle(meal.kind))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var groceryReferenceSection: some View {
        Section("Grocery reference") {
            ForEach(groceryReferenceSections) { section in
                DisclosureGroup(section.category.rawValue) {
                    ForEach(section.items) { item in
                        LabeledContent(item.name, value: item.quantity)
                    }
                }
            }
        }
    }

    private var sundayPrepSection: some View {
        Section("Sunday prep") {
            ForEach(selectedProgram.prepSteps, id: \.self) { step in
                Text(step)
                    .font(.subheadline)
                    .padding(.vertical, 3)
            }
        }
    }

    private func planPhase(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func prepStep(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private func metricPill(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.subheadline.weight(.bold))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func activeTrainingDays(in program: TrainingProgram) -> Int {
        program.weeklySchedule.filter { !$0.isRestDay }.count
    }

    private func retestPhase(for program: TrainingProgram) -> AssessmentPhase? {
        guard program.id == state.selectedProgram.id,
              let personalizedProgram = state.personalizedPrograms.first(where: { $0.baseProgramID == program.id }) else {
            return nil
        }

        return PersonalizationCalculator.nextRetestPhase(
            program: personalizedProgram,
            assessments: state.fitnessAssessments,
            on: Date()
        )
    }

    private func weekdayTitle(_ weekday: Weekday) -> String {
        switch weekday {
        case .sunday: "Sunday"
        case .monday: "Monday"
        case .tuesday: "Tuesday"
        case .wednesday: "Wednesday"
        case .thursday: "Thursday"
        case .friday: "Friday"
        case .saturday: "Saturday"
        }
    }

    private func mealKindTitle(_ kind: MealKind) -> String {
        switch kind {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .preWorkout: "Pre-workout"
        case .postWorkout: "Post-workout"
        }
    }
}

private struct RetestContext: Identifiable {
    let program: TrainingProgram
    let phase: AssessmentPhase

    var id: String {
        "\(program.id)-\(phase.rawValue)"
    }
}
