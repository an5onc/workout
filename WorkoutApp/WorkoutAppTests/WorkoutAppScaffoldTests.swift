import XCTest

final class WorkoutAppScaffoldTests: XCTestCase {
    func testScaffoldLoads() {
        XCTAssertTrue(true)
    }

    func testFoodAndGroceryScreensExist() {
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourcePath("WorkoutApp/Features/Food/FoodView.swift")))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sourcePath("WorkoutApp/Features/Grocery/GroceryView.swift")))
    }

    func testRootTabViewWiresFoodAndGroceryScreens() throws {
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)

        XCTAssertTrue(rootTabView.contains("FoodView(state: state)"))
        XCTAssertTrue(rootTabView.contains("GroceryView(state: state)"))
    }

    func testPlanReferenceScreenExistsAndIsWired() throws {
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)
        let planViewPath = sourcePath("WorkoutApp/Features/Plan/PlanView.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: planViewPath))
        XCTAssertTrue(rootTabView.contains("PlanView(state: state)"))

        let planView = try String(contentsOfFile: planViewPath, encoding: .utf8)
        XCTAssertTrue(planView.contains("struct PlanView: View"))
        XCTAssertTrue(planView.contains(".searchable"))
        XCTAssertTrue(planView.contains("Link(\"Demo\""))
        XCTAssertTrue(planView.contains("state.selectedProgram.weeklySchedule"))
    }

    func testPlanGroceryReferenceUsesMergedGrocerySections() throws {
        let planView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Plan/PlanView.swift"), encoding: .utf8)

        XCTAssertTrue(planView.contains("GroceryListGenerator.generate(from: selectedProgram.mealTemplates)"))
        XCTAssertTrue(planView.contains("ForEach(section.items)"))
        XCTAssertFalse(planView.contains("ForEach(section.ingredients"))
    }

    func testLocalAppStateDoesNotExposeLegacyTopLevelQuickProteinAdds() throws {
        let localAppState = try String(contentsOfFile: sourcePath("WorkoutApp/Store/LocalAppState.swift"), encoding: .utf8)

        XCTAssertFalse(localAppState.contains("var quickProteinAdds: [Int] { didSet { save() } }"))
    }

    func testFoodViewDerivesCurrentDateInsteadOfStoringTodayState() throws {
        let foodView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Food/FoodView.swift"), encoding: .utf8)

        XCTAssertFalse(foodView.contains("@State private var today = Date()"))
        XCTAssertTrue(foodView.contains("let currentDate: () -> Date"))
    }

    func testPrepAheadViewExistsAndIsWiredIntoToday() throws {
        let prepAheadPath = sourcePath("WorkoutApp/Features/Today/PrepAheadView.swift")
        let todayView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/TodayView.swift"), encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: prepAheadPath))
        XCTAssertTrue(todayView.contains("selectedPrepAheadOffset"))
        XCTAssertTrue(todayView.contains("ForEach(1...7"))
        XCTAssertTrue(todayView.contains("PrepAheadView(workout: futureWorkout, futureDate: futureDate, state: state)"))
    }

    func testPrepAheadViewDoesNotExposeLiveWorkoutCompletionControls() throws {
        let prepAheadView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/PrepAheadView.swift"), encoding: .utf8)

        XCTAssertFalse(prepAheadView.contains("finishWorkout"))
        XCTAssertFalse(prepAheadView.contains("toggleSet"))
        XCTAssertFalse(prepAheadView.contains("Mark workout finished"))
        XCTAssertFalse(prepAheadView.contains("restTimer"))
        XCTAssertFalse(prepAheadView.contains("ExerciseCardView("))
        XCTAssertTrue(prepAheadView.contains("PrepAheadExerciseCard"))
    }

    func testFeatureScreensUseSelectedProgramContent() throws {
        let todayView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/TodayView.swift"), encoding: .utf8)
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)
        let foodView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Food/FoodView.swift"), encoding: .utf8)
        let groceryView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Grocery/GroceryView.swift"), encoding: .utf8)
        let planView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Plan/PlanView.swift"), encoding: .utf8)

        XCTAssertTrue(todayView.contains("state.selectedProgram"))
        XCTAssertTrue(rootTabView.contains("state.selectedProgram.weeklySchedule"))
        XCTAssertTrue(foodView.contains("state.selectedProgram"))
        XCTAssertTrue(groceryView.contains("state.selectedProgram"))
        XCTAssertTrue(planView.contains("state.selectedProgram"))
        XCTAssertTrue(planView.contains("state.selectProgram(id: program.id)"))
        XCTAssertTrue(planView.contains("Use this plan"))
    }

    func testPlanSwitchUsesConfirmationDialogBeforeChangingProgram() throws {
        let planView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Plan/PlanView.swift"), encoding: .utf8)

        XCTAssertTrue(planView.contains("pendingProgramSelection"))
        XCTAssertTrue(planView.contains(".confirmationDialog("))
        XCTAssertTrue(planView.contains("Switch plans"))
        XCTAssertTrue(planView.contains("state.selectProgram(id: program.id)"))
    }

    func testPlanChooserShowsGoalCardsAndPreview() throws {
        let planView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Plan/PlanView.swift"), encoding: .utf8)
        let todayView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/TodayView.swift"), encoding: .utf8)

        XCTAssertTrue(planView.contains("programGoalOverviewSection"))
        XCTAssertTrue(planView.contains("previewProgramID"))
        XCTAssertTrue(planView.contains("selectedProgramPreview"))
        XCTAssertTrue(planView.contains("goalCard("))
        XCTAssertTrue(planView.contains("Plan preview"))
        XCTAssertTrue(todayView.contains("currentGoalStatus"))
        XCTAssertTrue(todayView.contains("Goal"))
    }

    func testProgressDashboardShowsWeightLossMetrics() throws {
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)

        XCTAssertTrue(rootTabView.contains("weightLossMetricsSection"))
        XCTAssertTrue(rootTabView.contains("Weight-loss metrics"))
        XCTAssertTrue(rootTabView.contains("Body weight trend"))
        XCTAssertTrue(rootTabView.contains("Waist trend"))
        XCTAssertTrue(rootTabView.contains("Weekly adherence"))
        XCTAssertTrue(rootTabView.contains("Walking/cardio"))
        XCTAssertTrue(rootTabView.contains("ProgressMetricsCalculator"))
    }

    func testPlanPersonalizationFlowExistsAndIsWired() throws {
        let planView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Plan/PlanView.swift"), encoding: .utf8)
        let flowPath = sourcePath("WorkoutApp/Features/Plan/PersonalizationFlowView.swift")

        XCTAssertTrue(FileManager.default.fileExists(atPath: flowPath))
        let flowView = try String(contentsOfFile: flowPath, encoding: .utf8)

        XCTAssertTrue(planView.contains("Personalize plan"))
        XCTAssertTrue(planView.contains("PersonalizationFlowView"))
        XCTAssertTrue(flowView.contains("Baseline assessment"))
        XCTAssertTrue(flowView.contains("Push-up test"))
        XCTAssertTrue(flowView.contains("Step test"))
        XCTAssertTrue(flowView.contains("1-mile treadmill"))
        XCTAssertTrue(flowView.contains("finalizePersonalizedProgram"))
    }

    func testTodayAndProgressExposeAssessmentStatus() throws {
        let todayView = try String(contentsOfFile: sourcePath("WorkoutApp/Features/Today/TodayView.swift"), encoding: .utf8)
        let rootTabView = try String(contentsOfFile: sourcePath("WorkoutApp/App/RootTabView.swift"), encoding: .utf8)

        XCTAssertTrue(todayView.contains("retestPromptSection"))
        XCTAssertTrue(todayView.contains("Retest due"))
        XCTAssertTrue(todayView.contains("Training level"))
        XCTAssertTrue(rootTabView.contains("assessmentProgressSection"))
        XCTAssertTrue(rootTabView.contains("Assessment progress"))
        XCTAssertTrue(rootTabView.contains("Push-ups"))
        XCTAssertTrue(rootTabView.contains("Step test"))
        XCTAssertTrue(rootTabView.contains("1-mile treadmill"))
    }

    private func sourcePath(_ path: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: path)
            .path
    }
}
