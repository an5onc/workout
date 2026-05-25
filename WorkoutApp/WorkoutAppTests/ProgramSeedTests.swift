import XCTest
@testable import WorkoutApp

final class ProgramSeedTests: XCTestCase {
    func testProgramLibraryContainsDefaultAndWeightLossPrograms() throws {
        let ids = ProgramSeed.programs.map(\.id)

        XCTAssertGreaterThanOrEqual(ProgramSeed.programs.count, 2)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(ProgramSeed.defaultProgramID, "lower-body-strength-recomp")
        XCTAssertEqual(ProgramSeed.defaultProgram.name, "Lower Body Strength + Recomp")
        XCTAssertNotNil(ProgramSeed.program(id: "weight-loss-foundation"))
    }

    func testWeightLossProgramHasSevenDayScheduleAndConditioningFocus() throws {
        let program = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))

        XCTAssertEqual(program.weeklySchedule.count, 7)
        XCTAssertEqual(program.goal, "Weight loss")
        XCTAssertTrue(program.weeklySchedule.contains { $0.focus.localizedCaseInsensitiveContains("conditioning") })
        XCTAssertLessThan(program.nutritionTargets.calories, ProgramSeed.defaultProgram.nutritionTargets.calories)
        XCTAssertTrue(program.mealTemplates.allSatisfy { !$0.ingredients.isEmpty })
    }

    func testWeightLossStrengthExercisesIncludeSubstitutions() throws {
        let program = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))
        let exercises = program.weeklySchedule.flatMap(\.exercises)
        let goblet = try XCTUnwrap(exercises.first { $0.id == "wl-goblet-squat" })
        let row = try XCTUnwrap(exercises.first { $0.id == "wl-seated-cable-row" })
        let legPress = try XCTUnwrap(exercises.first { $0.id == "wl-leg-press" })

        XCTAssertGreaterThanOrEqual(goblet.substitutions.count, 2)
        XCTAssertGreaterThanOrEqual(row.substitutions.count, 2)
        XCTAssertGreaterThanOrEqual(legPress.substitutions.count, 2)
        XCTAssertTrue([goblet, row, legPress].flatMap(\.substitutions).allSatisfy { $0.demoURL != nil })
    }

    func testWeightLossProgramHasExpandedMealVariety() throws {
        let program = try XCTUnwrap(ProgramSeed.program(id: "weight-loss-foundation"))

        XCTAssertGreaterThanOrEqual(program.mealTemplates.count, 7)
        XCTAssertTrue(program.mealTemplates.contains { $0.kind == .dinner && $0.name == "Shrimp Fajita Bowl" })
        XCTAssertTrue(program.mealTemplates.contains { $0.kind == .snack && $0.name == "Tuna Cucumber Plate" })
    }

    func testWeeklyScheduleHasSevenDays() {
        XCTAssertEqual(ProgramSeed.weeklySchedule.count, 7)
        XCTAssertEqual(ProgramSeed.workout(for: .monday)?.name, "Lower A")
        XCTAssertEqual(ProgramSeed.workout(for: .thursday)?.isRestDay, true)
        XCTAssertEqual(ProgramSeed.workout(for: .sunday)?.name, "Rest day + meal prep")
    }

    func testLowerAIncludesPlanExercises() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        XCTAssertEqual(lowerA.exercises.map(\.name), [
            "Barbell Hip Thrust",
            "Heel-Elevated Goblet Squat",
            "DB Walking Lunge",
            "Leg Extension Machine",
            "Standing Calf Raise"
        ])
        XCTAssertEqual(lowerA.exercises.first?.sets, 4)
        XCTAssertEqual(lowerA.exercises.first?.repRange, "8-10")
    }

    func testMajorExercisesIncludeSubstitutionsForBusyGymFlow() throws {
        let allExercises = ProgramSeed.weeklySchedule.flatMap(\.exercises)
        let hipThrust = try XCTUnwrap(allExercises.first { $0.id == "barbell-hip-thrust" })
        let dbBench = try XCTUnwrap(allExercises.first { $0.id == "db-bench-press" })
        let latPulldown = try XCTUnwrap(allExercises.first { $0.id == "lat-pulldown" })

        XCTAssertGreaterThanOrEqual(hipThrust.substitutions.count, 2)
        XCTAssertTrue(hipThrust.substitutions.contains { $0.name == "Smith Machine Hip Thrust" })
        XCTAssertTrue(dbBench.substitutions.contains { $0.name == "Machine Chest Press" })
        XCTAssertTrue(latPulldown.substitutions.contains { $0.name == "Assisted Pull-Up Machine" })
        XCTAssertTrue([hipThrust, dbBench, latPulldown].flatMap(\.substitutions).allSatisfy { $0.demoURL != nil })
    }

    func testAllSeedExerciseDemoLinksAreCuratedNotSearches() {
        let exercises = ProgramSeed.programs.flatMap(\.weeklySchedule).flatMap(\.exercises)
        let substitutions = exercises.flatMap(\.substitutions)
        let urls = exercises.compactMap(\.demoURL) + substitutions.compactMap(\.demoURL)

        XCTAssertFalse(exercises.isEmpty)
        XCTAssertEqual(urls.count, exercises.count + substitutions.count)
        XCTAssertTrue(urls.allSatisfy { $0.host == "musclewiki.com" })
        XCTAssertFalse(urls.contains { $0.absoluteString.contains("youtube.com/results") })
        XCTAssertFalse(urls.contains { $0.absoluteString.contains("search_query") })
    }

    func testMealTemplatesSupportGroceryBuilder() {
        XCTAssertTrue(ProgramSeed.mealTemplates.contains { $0.name == "Protein Oatmeal" })
        XCTAssertTrue(ProgramSeed.mealTemplates.contains { $0.name == "Chicken & Rice Power Bowl" })
        XCTAssertTrue(ProgramSeed.mealTemplates.allSatisfy { !$0.ingredients.isEmpty })
    }

    func testNutritionTargetsAreTyped() {
        let targets: NutritionTargets = ProgramSeed.nutritionTargets

        XCTAssertEqual(targets.calories, 1600)
        XCTAssertEqual(targets.proteinGrams, 145)
        XCTAssertEqual(targets.fatGrams, 50)
        XCTAssertEqual(targets.carbsGrams, 145)
        XCTAssertEqual(targets.waterOunces, 100)
    }

    func testMealTemplatesIncludeStructuredMacros() throws {
        let oatmeal = try XCTUnwrap(ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" })

        XCTAssertEqual(oatmeal.calories, 410)
        XCTAssertEqual(oatmeal.proteinGrams, 31)
        XCTAssertEqual(oatmeal.fatGrams, 11)
        XCTAssertEqual(oatmeal.carbsGrams, 48)
    }

    func testMealTemplatesIncludeGroceryCategoryAndQuantity() throws {
        let chickenBowl = try XCTUnwrap(ProgramSeed.mealTemplates.first { $0.name == "Chicken & Rice Power Bowl" })
        let chicken = try XCTUnwrap(chickenBowl.ingredients.first { $0.id == "chicken-breast" })

        XCTAssertEqual(chicken.category, .meatSeafood)
        XCTAssertEqual(chicken.quantity, "5 oz")
    }

    func testQuickProteinAnchorsIncludePlanItemsWithLabelsAndGrams() {
        let anchorsByID = Dictionary(uniqueKeysWithValues: ProgramSeed.quickProteinAnchors.map { ($0.id, $0) })

        XCTAssertEqual(anchorsByID["whey"]?.label, "Whey")
        XCTAssertEqual(anchorsByID["whey"]?.proteinGrams, 25)
        XCTAssertEqual(anchorsByID["greek-yogurt"]?.label, "Greek yogurt")
        XCTAssertEqual(anchorsByID["greek-yogurt"]?.proteinGrams, 20)
        XCTAssertEqual(anchorsByID["chicken"]?.label, "Chicken")
        XCTAssertEqual(anchorsByID["chicken"]?.proteinGrams, 30)
        XCTAssertEqual(anchorsByID["eggs"]?.label, "Eggs")
        XCTAssertEqual(anchorsByID["eggs"]?.proteinGrams, 12)
        XCTAssertEqual(anchorsByID["tuna"]?.label, "Tuna")
        XCTAssertEqual(anchorsByID["tuna"]?.proteinGrams, 25)
    }
}
