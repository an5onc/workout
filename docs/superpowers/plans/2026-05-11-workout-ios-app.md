# Workout iOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native, personal/local-only SwiftUI iPhone app for the approved 12-week workout plan, optimized for gym workout flow and template-based grocery generation.

**Architecture:** Create a new XcodeGen-backed iOS project under `WorkoutApp/`. Keep seed program data in typed Swift models, keep pure workout/food/grocery logic testable outside SwiftUI views, and use `@AppStorage`/JSON-backed local state for v1 persistence. SwiftUI screens consume the same seed models used by tests.

**Tech Stack:** Swift 6, SwiftUI, XCTest, XcodeGen, Xcode 26.2, iOS Simulator.

---

## File Structure

- Create `WorkoutApp/project.yml`: XcodeGen project definition for app and test targets.
- Create `WorkoutApp/WorkoutApp/App/WorkoutApp.swift`: app entry point.
- Create `WorkoutApp/WorkoutApp/App/RootTabView.swift`: tab shell for Today, Food, Grocery, and Plan.
- Create `WorkoutApp/WorkoutApp/Models/ProgramModels.swift`: read-only seed models.
- Create `WorkoutApp/WorkoutApp/Models/UserLogModels.swift`: local log models.
- Create `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift`: bundled plan content from `12_Week_Plan.docx` and `daily_companion.html`.
- Create `WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift`: today lookup, manual override, active exercise advancement.
- Create `WorkoutApp/WorkoutApp/Core/ProteinTracker.swift`: protein total calculations.
- Create `WorkoutApp/WorkoutApp/Core/GroceryListGenerator.swift`: meal template to categorized grocery list.
- Create `WorkoutApp/WorkoutApp/Store/LocalAppState.swift`: simple local state container with UserDefaults JSON persistence.
- Create `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift`: workout/rest-day UI.
- Create `WorkoutApp/WorkoutApp/Features/Today/ExerciseCardView.swift`: expanded/collapsed exercise cards.
- Create `WorkoutApp/WorkoutApp/Features/Food/FoodView.swift`: protein and meals UI.
- Create `WorkoutApp/WorkoutApp/Features/Grocery/GroceryView.swift`: meal picker and generated list UI.
- Create `WorkoutApp/WorkoutApp/Features/Plan/PlanView.swift`: reference UI with exercise library.
- Create `WorkoutApp/WorkoutApp/Design/AppTheme.swift`: shared colors and typography helpers.
- Create `WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift`.
- Create `WorkoutApp/WorkoutAppTests/ProteinTrackerTests.swift`.
- Create `WorkoutApp/WorkoutAppTests/GroceryListGeneratorTests.swift`.
- Modify `.gitignore`: exclude `.superpowers/`, Xcode derived data, and generated build artifacts.

---

### Task 1: Scaffold Deterministic iOS Project

**Files:**
- Create: `WorkoutApp/project.yml`
- Create: `WorkoutApp/WorkoutApp/App/WorkoutApp.swift`
- Create: `WorkoutApp/WorkoutApp/App/RootTabView.swift`
- Create: `WorkoutApp/WorkoutApp/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `WorkoutApp/WorkoutApp/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Modify: `.gitignore`

- [ ] **Step 1: Install XcodeGen if missing**

Run:

```bash
command -v xcodegen || brew install xcodegen
```

Expected: `xcodegen` is available on PATH.

- [ ] **Step 2: Add project definition**

Create `WorkoutApp/project.yml`:

```yaml
name: WorkoutApp
options:
  bundleIdPrefix: com.ansoncordeiro
  deploymentTarget:
    iOS: "18.0"
settings:
  base:
    SWIFT_VERSION: "6.0"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
targets:
  WorkoutApp:
    type: application
    platform: iOS
    sources:
      - WorkoutApp
    resources:
      - WorkoutApp/Assets.xcassets
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.ansoncordeiro.WorkoutApp
        INFOPLIST_KEY_CFBundleDisplayName: Workout
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES
  WorkoutAppTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - WorkoutAppTests
    dependencies:
      - target: WorkoutApp
```

- [ ] **Step 3: Add minimal app entry**

Create `WorkoutApp/WorkoutApp/App/WorkoutApp.swift`:

```swift
import SwiftUI

@main
struct WorkoutApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}
```

Create `WorkoutApp/WorkoutApp/App/RootTabView.swift`:

```swift
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Text("Today")
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            Text("Food")
                .tabItem { Label("Food", systemImage: "fork.knife") }

            Text("Grocery")
                .tabItem { Label("Grocery", systemImage: "cart") }

            Text("Plan")
                .tabItem { Label("Plan", systemImage: "book") }
        }
    }
}
```

- [ ] **Step 4: Add asset placeholders**

Create `WorkoutApp/WorkoutApp/Assets.xcassets/AccentColor.colorset/Contents.json`:

```json
{
  "colors": [
    {
      "idiom": "universal",
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.478",
          "green": "0.184",
          "blue": "0.309",
          "alpha": "1.000"
        }
      }
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

Create `WorkoutApp/WorkoutApp/Assets.xcassets/AppIcon.appiconset/Contents.json`:

```json
{
  "images": [],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

- [ ] **Step 5: Ignore generated files**

Create or update `.gitignore`:

```gitignore
.superpowers/
.DS_Store
DerivedData/
WorkoutApp/*.xcworkspace
WorkoutApp/WorkoutApp.xcodeproj/xcuserdata/
WorkoutApp/WorkoutApp.xcodeproj/project.xcworkspace/xcuserdata/
```

- [ ] **Step 6: Generate and build**

Run:

```bash
cd WorkoutApp
xcodegen generate
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' build
```

Expected: build succeeds.

- [ ] **Step 7: Commit**

```bash
git add .gitignore WorkoutApp
git commit -m "chore: scaffold workout iOS app"
```

---

### Task 2: Add Program Models And Seed Data Under Test

**Files:**
- Create: `WorkoutApp/WorkoutApp/Models/ProgramModels.swift`
- Create: `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift`
- Create: `WorkoutApp/WorkoutAppTests/ProgramSeedTests.swift`

- [ ] **Step 1: Write failing seed tests**

Create `WorkoutApp/WorkoutAppTests/ProgramSeedTests.swift`:

```swift
import XCTest
@testable import WorkoutApp

final class ProgramSeedTests: XCTestCase {
    func testWeeklyScheduleHasSevenDays() {
        XCTAssertEqual(ProgramSeed.weeklySchedule.count, 7)
        XCTAssertEqual(ProgramSeed.workout(for: .monday)?.name, "Lower A")
        XCTAssertEqual(ProgramSeed.workout(for: .thursday)?.isRestDay, true)
        XCTAssertEqual(ProgramSeed.workout(for: .sunday)?.name, "Rest day + meal prep")
    }

    func testLowerAIncludesPlanExercises() {
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

    func testMealTemplatesSupportGroceryBuilder() {
        XCTAssertTrue(ProgramSeed.mealTemplates.contains { $0.name == "Protein Oatmeal" })
        XCTAssertTrue(ProgramSeed.mealTemplates.contains { $0.name == "Chicken & Rice Power Bowl" })
        XCTAssertTrue(ProgramSeed.mealTemplates.allSatisfy { !$0.ingredients.isEmpty })
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/ProgramSeedTests
```

Expected: FAIL because `ProgramSeed` and model types do not exist.

- [ ] **Step 3: Add model types**

Create `WorkoutApp/WorkoutApp/Models/ProgramModels.swift`:

```swift
import Foundation

enum Weekday: String, CaseIterable, Identifiable, Codable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var id: String { rawValue }
}

enum MealKind: String, CaseIterable, Identifiable, Codable {
    case breakfast, lunch, dinner, snack, preWorkout, postWorkout

    var id: String { rawValue }
}

enum GroceryCategory: String, CaseIterable, Identifiable, Codable {
    case produce = "Produce"
    case meatSeafood = "Meat & Seafood"
    case dairyEggs = "Dairy & Eggs"
    case pantry = "Pantry"
    case supplementsExtras = "Supplements & Extras"
    case other = "Other"

    var id: String { rawValue }
}

struct Exercise: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let sets: Int
    let repRange: String
    let rest: String
    let cue: String
    let formCues: [String]
    let mistakes: [String]
    let feel: String
    let demoURL: URL?
}

struct WorkoutDay: Identifiable, Hashable, Codable {
    let id: Weekday
    let name: String
    let focus: String
    let subtitle: String
    let isRestDay: Bool
    let exercises: [Exercise]
}

struct Ingredient: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let quantity: String
    let category: GroceryCategory
}

struct MealTemplate: Identifiable, Hashable, Codable {
    let id: String
    let kind: MealKind
    let name: String
    let detail: String
    let proteinGrams: Int
    let ingredients: [Ingredient]
}
```

- [ ] **Step 4: Add seed content**

Create `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift` with all workout days and initial meal templates:

```swift
import Foundation

enum ProgramSeed {
    static let nutritionTargets = (calories: 1600, protein: 145, fat: 50, carbs: 145, waterOunces: 100)

    static let weeklySchedule: [WorkoutDay] = [
        WorkoutDay(id: .sunday, name: "Rest day + meal prep", focus: "Rest", subtitle: "Full rest. Sunday meal prep day.", isRestDay: true, exercises: []),
        WorkoutDay(id: .monday, name: "Lower A", focus: "Glute + Quad", subtitle: "Compound glute-builder, then quad-dominant work.", isRestDay: false, exercises: [
            exercise("barbell-hip-thrust", "Barbell Hip Thrust", 4, "8-10", "90-120s", "Top set is the heaviest."),
            exercise("heel-elevated-goblet-squat", "Heel-Elevated Goblet Squat", 3, "10", "75-90s", "Plates under heels, deep range."),
            exercise("db-walking-lunge", "DB Walking Lunge", 3, "10/leg", "60-90s", "Long steps."),
            exercise("leg-extension-machine", "Leg Extension Machine", 3, "12", "60s", "Squeeze at top, slow lower."),
            exercise("standing-calf-raise", "Standing Calf Raise", 3, "15", "45-60s", "Full stretch at the bottom.")
        ]),
        WorkoutDay(id: .tuesday, name: "Upper Push", focus: "Chest, shoulders, triceps", subtitle: "Chest, shoulders, triceps.", isRestDay: false, exercises: [
            exercise("db-bench-press", "DB Bench Press", 3, "8-10", "90s", "Control the lowering."),
            exercise("seated-db-shoulder-press", "Seated DB Shoulder Press", 3, "8-10", "90s", "Bench at 80-85 degrees."),
            exercise("cable-lateral-raise", "Cable Lateral Raise", 3, "12", "45-60s", "Lead with the elbow."),
            exercise("incline-db-press", "Incline DB Press", 3, "10", "90s", "30 degrees, not steeper."),
            exercise("triceps-rope-pushdown", "Triceps Rope Pushdown", 3, "12", "45-60s", "Elbows pinned to ribs."),
            exercise("plank", "Plank", 3, "30-45 seconds", "60s", "Glutes squeezed.")
        ]),
        WorkoutDay(id: .wednesday, name: "Lower B", focus: "Glute + Hamstring", subtitle: "Posterior chain emphasis.", isRestDay: false, exercises: [
            exercise("barbell-romanian-deadlift", "Barbell Romanian Deadlift", 4, "8-10", "90-120s", "Hinge, do not squat."),
            exercise("cable-glute-kickback", "Cable Glute Kickback", 3, "12/leg", "45s", "Squeeze at the top."),
            exercise("db-bulgarian-split-squat", "DB Bulgarian Split Squat", 3, "8/leg", "60-90s", "Slight forward lean."),
            exercise("seated-hamstring-curl", "Seated Hamstring Curl", 3, "12", "60s", "Slow eccentric."),
            exercise("hip-abduction-machine", "Hip Abduction Machine", 3, "15", "45-60s", "Lean forward 15 degrees."),
            exercise("hanging-knee-raise", "Hanging Knee Raise", 3, "10-12", "60s", "Roll the hips up.")
        ]),
        WorkoutDay(id: .thursday, name: "Rest day", focus: "Rest", subtitle: "Full recovery. Optional 20-30 minute walk. No lifting.", isRestDay: true, exercises: []),
        WorkoutDay(id: .friday, name: "Upper Pull", focus: "Back, biceps, core", subtitle: "Back and biceps.", isRestDay: false, exercises: [
            exercise("lat-pulldown", "Lat Pulldown", 4, "10", "90s", "Elbows to ribs."),
            exercise("seated-cable-row", "Seated Cable Row", 3, "10", "90s", "Squeeze the shoulder blades."),
            exercise("db-single-arm-row", "DB Single-Arm Row", 3, "10/arm", "60s", "Do not twist the torso."),
            exercise("cable-face-pull", "Cable Face Pull", 3, "12-15", "45-60s", "Elbows up and out."),
            exercise("db-curl", "DB Curl", 3, "10", "60s", "Squeeze at the top."),
            exercise("pallof-press", "Pallof Press", 3, "10/side", "45s", "Resist the rotation.")
        ]),
        WorkoutDay(id: .saturday, name: "Lower C", focus: "Glute Volume Day", subtitle: "Highest-volume glute day of the week.", isRestDay: false, exercises: [
            exercise("smith-machine-hip-thrust", "Smith Machine Hip Thrust", 4, "12", "90s", "Push the weight."),
            exercise("db-sumo-deadlift", "DB Sumo Deadlift", 3, "8", "90s", "Drive knees out."),
            exercise("db-step-up", "DB Step-Up", 3, "10/leg", "60s", "Drive through the heel."),
            exercise("cable-pull-through", "Cable Pull-Through", 3, "12", "60-75s", "Squeeze the glutes hard at the top."),
            exercise("hip-abduction-machine-saturday", "Hip Abduction Machine", 3, "15 + drop set on last", "60s", "Drop set on last set.")
        ])
    ]

    static let mealTemplates: [MealTemplate] = [
        meal("protein-oatmeal", .breakfast, "Protein Oatmeal", "Oats, whey, peanut butter, banana, cinnamon.", 31, [
            ingredient("rolled-oats", "Rolled oats", "1/2 cup", .pantry),
            ingredient("whey-protein", "Whey protein", "1 scoop", .supplementsExtras),
            ingredient("natural-peanut-butter", "Natural peanut butter", "1 tbsp", .pantry),
            ingredient("banana", "Banana", "1/2", .produce)
        ]),
        meal("greek-yogurt-power-bowl", .breakfast, "Greek Yogurt Power Bowl", "Greek yogurt, berries, honey, granola, chia.", 28, [
            ingredient("greek-yogurt", "Non-fat Greek yogurt", "1 cup", .dairyEggs),
            ingredient("berries", "Mixed berries", "1/2 cup", .produce),
            ingredient("honey", "Honey", "1 tbsp", .pantry),
            ingredient("granola", "Granola", "2 tbsp", .pantry),
            ingredient("chia-seeds", "Chia seeds", "1 tbsp", .pantry)
        ]),
        meal("chicken-rice-power-bowl", .lunch, "Chicken & Rice Power Bowl", "Chicken breast, rice, broccoli, olive oil, lemon.", 42, [
            ingredient("chicken-breast", "Boneless skinless chicken breast", "5 oz", .meatSeafood),
            ingredient("jasmine-rice", "Jasmine rice", "1/2 cup cooked", .pantry),
            ingredient("broccoli", "Broccoli", "1 cup", .produce),
            ingredient("olive-oil", "Olive oil", "1 tbsp", .pantry),
            ingredient("lemon", "Lemon", "1", .produce)
        ]),
        meal("sheet-pan-salmon-veg", .dinner, "Sheet-Pan Salmon & Veg", "Salmon, zucchini, bell peppers, sweet potato.", 35, [
            ingredient("salmon", "Salmon fillet", "5 oz", .meatSeafood),
            ingredient("zucchini", "Zucchini", "1 cup", .produce),
            ingredient("bell-peppers", "Bell peppers", "1 cup", .produce),
            ingredient("sweet-potato", "Sweet potato", "1/2", .produce)
        ]),
        meal("protein-shake", .snack, "Protein Shake", "Whey with water or almond milk.", 25, [
            ingredient("whey-protein", "Whey protein", "1 scoop", .supplementsExtras),
            ingredient("almond-milk", "Unsweetened almond milk", "1 cup", .dairyEggs)
        ])
    ]

    static func workout(for weekday: Weekday) -> WorkoutDay? {
        weeklySchedule.first { $0.id == weekday }
    }

    private static func exercise(_ id: String, _ name: String, _ sets: Int, _ reps: String, _ rest: String, _ cue: String) -> Exercise {
        Exercise(
            id: id,
            name: name,
            sets: sets,
            repRange: reps,
            rest: rest,
            cue: cue,
            formCues: [cue, "Brace your core.", "Control the lowering phase."],
            mistakes: ["Using momentum.", "Letting form break down."],
            feel: "Target muscles working without sharp pain.",
            demoURL: URL(string: "https://www.youtube.com/results?search_query=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)+proper+form")
        )
    }

    private static func meal(_ id: String, _ kind: MealKind, _ name: String, _ detail: String, _ protein: Int, _ ingredients: [Ingredient]) -> MealTemplate {
        MealTemplate(id: id, kind: kind, name: name, detail: detail, proteinGrams: protein, ingredients: ingredients)
    }

    private static func ingredient(_ id: String, _ name: String, _ quantity: String, _ category: GroceryCategory) -> Ingredient {
        Ingredient(id: id, name: name, quantity: quantity, category: category)
    }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/ProgramSeedTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add WorkoutApp/WorkoutApp/Models WorkoutApp/WorkoutApp/ProgramData WorkoutApp/WorkoutAppTests/ProgramSeedTests.swift
git commit -m "feat: add workout program seed data"
```

---

### Task 3: Implement Workout Planning Logic With TDD

**Files:**
- Create: `WorkoutApp/WorkoutApp/Models/UserLogModels.swift`
- Create: `WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift`
- Create: `WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift`

- [ ] **Step 1: Write failing workout planner tests**

Create `WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift`:

```swift
import XCTest
@testable import WorkoutApp

final class WorkoutPlannerTests: XCTestCase {
    func testWeekdayLookupUsesManualOverrideWhenPresent() {
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let workout = planner.workout(for: .monday, override: .saturday)
        XCTAssertEqual(workout?.name, "Lower C")
    }

    func testWeekdayLookupFallsBackToCurrentDay() {
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let workout = planner.workout(for: .monday, override: nil)
        XCTAssertEqual(workout?.name, "Lower A")
    }

    func testActiveExerciseAdvancesAfterCompletedSets() throws {
        let lowerA = try XCTUnwrap(ProgramSeed.workout(for: .monday))
        let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
        let completed = SetProgress(exerciseID: "barbell-hip-thrust", completedSets: [0, 1, 2, 3])
        let active = planner.activeExercise(in: lowerA, progress: [completed])
        XCTAssertEqual(active?.id, "heel-elevated-goblet-squat")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/WorkoutPlannerTests
```

Expected: FAIL because `WorkoutPlanner` and `SetProgress` do not exist.

- [ ] **Step 3: Add user log model and planner**

Create `WorkoutApp/WorkoutApp/Models/UserLogModels.swift`:

```swift
import Foundation

struct SetProgress: Identifiable, Hashable, Codable {
    var id: String { exerciseID }
    let exerciseID: String
    var completedSets: Set<Int>
    var weightText: String
    var repsText: String
    var rpeText: String

    init(exerciseID: String, completedSets: Set<Int> = [], weightText: String = "", repsText: String = "", rpeText: String = "") {
        self.exerciseID = exerciseID
        self.completedSets = completedSets
        self.weightText = weightText
        self.repsText = repsText
        self.rpeText = rpeText
    }
}
```

Create `WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift`:

```swift
import Foundation

struct WorkoutPlanner {
    let schedule: [WorkoutDay]

    func workout(for currentDay: Weekday, override: Weekday?) -> WorkoutDay? {
        let selected = override ?? currentDay
        return schedule.first { $0.id == selected }
    }

    func activeExercise(in workout: WorkoutDay, progress: [SetProgress]) -> Exercise? {
        guard !workout.isRestDay else { return nil }
        for exercise in workout.exercises {
            let exerciseProgress = progress.first { $0.exerciseID == exercise.id }
            let completedCount = exerciseProgress?.completedSets.count ?? 0
            if completedCount < exercise.sets {
                return exercise
            }
        }
        return workout.exercises.last
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/WorkoutPlannerTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add WorkoutApp/WorkoutApp/Models/UserLogModels.swift WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift
git commit -m "feat: add workout planner logic"
```

---

### Task 4: Implement Protein Tracking With TDD

**Files:**
- Create: `WorkoutApp/WorkoutApp/Core/ProteinTracker.swift`
- Create: `WorkoutApp/WorkoutAppTests/ProteinTrackerTests.swift`

- [ ] **Step 1: Write failing protein tests**

Create `WorkoutApp/WorkoutAppTests/ProteinTrackerTests.swift`:

```swift
import XCTest
@testable import WorkoutApp

final class ProteinTrackerTests: XCTestCase {
    func testProteinTotalCombinesMealsAndQuickAdds() {
        let meals = [
            ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" }!,
            ProgramSeed.mealTemplates.first { $0.name == "Chicken & Rice Power Bowl" }!
        ]
        let total = ProteinTracker.totalProtein(meals: meals, quickAdds: [25, 12])
        XCTAssertEqual(total, 110)
    }

    func testProteinProgressCapsAtOneHundredPercent() {
        XCTAssertEqual(ProteinTracker.progress(total: 200, target: 145), 1.0)
        XCTAssertEqual(ProteinTracker.progress(total: 72, target: 144), 0.5)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/ProteinTrackerTests
```

Expected: FAIL because `ProteinTracker` does not exist.

- [ ] **Step 3: Add tracker**

Create `WorkoutApp/WorkoutApp/Core/ProteinTracker.swift`:

```swift
import Foundation

enum ProteinTracker {
    static func totalProtein(meals: [MealTemplate], quickAdds: [Int]) -> Int {
        meals.reduce(0) { $0 + $1.proteinGrams } + quickAdds.reduce(0, +)
    }

    static func progress(total: Int, target: Int) -> Double {
        guard target > 0 else { return 0 }
        return min(1, Double(total) / Double(target))
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/ProteinTrackerTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add WorkoutApp/WorkoutApp/Core/ProteinTracker.swift WorkoutApp/WorkoutAppTests/ProteinTrackerTests.swift
git commit -m "feat: add protein tracker logic"
```

---

### Task 5: Implement Grocery Generation With TDD

**Files:**
- Create: `WorkoutApp/WorkoutApp/Core/GroceryListGenerator.swift`
- Create: `WorkoutApp/WorkoutAppTests/GroceryListGeneratorTests.swift`

- [ ] **Step 1: Write failing grocery tests**

Create `WorkoutApp/WorkoutAppTests/GroceryListGeneratorTests.swift`:

```swift
import XCTest
@testable import WorkoutApp

final class GroceryListGeneratorTests: XCTestCase {
    func testGeneratedListGroupsByCategory() {
        let meals = [
            ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" }!,
            ProgramSeed.mealTemplates.first { $0.name == "Chicken & Rice Power Bowl" }!
        ]
        let sections = GroceryListGenerator.generate(from: meals)
        XCTAssertTrue(sections.contains { $0.category == .produce })
        XCTAssertTrue(sections.contains { $0.category == .pantry })
        XCTAssertTrue(sections.contains { $0.category == .meatSeafood })
    }

    func testDuplicateIngredientsMergeQuantitiesByName() {
        let meals = [
            ProgramSeed.mealTemplates.first { $0.name == "Protein Oatmeal" }!,
            ProgramSeed.mealTemplates.first { $0.name == "Protein Shake" }!
        ]
        let sections = GroceryListGenerator.generate(from: meals)
        let supplements = sections.first { $0.category == .supplementsExtras }
        let whey = supplements?.items.first { $0.name == "Whey protein" }
        XCTAssertEqual(whey?.quantity, "1 scoop + 1 scoop")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/GroceryListGeneratorTests
```

Expected: FAIL because `GroceryListGenerator` does not exist.

- [ ] **Step 3: Add generator**

Create `WorkoutApp/WorkoutApp/Core/GroceryListGenerator.swift`:

```swift
import Foundation

struct GroceryItem: Identifiable, Hashable {
    let id: String
    let name: String
    let quantity: String
    let category: GroceryCategory
}

struct GrocerySection: Identifiable, Hashable {
    var id: GroceryCategory { category }
    let category: GroceryCategory
    let items: [GroceryItem]
}

enum GroceryListGenerator {
    static func generate(from meals: [MealTemplate]) -> [GrocerySection] {
        var merged: [String: GroceryItem] = [:]

        for ingredient in meals.flatMap(\.ingredients) {
            let key = ingredient.name.lowercased()
            if let existing = merged[key] {
                merged[key] = GroceryItem(
                    id: existing.id,
                    name: existing.name,
                    quantity: existing.quantity + " + " + ingredient.quantity,
                    category: existing.category
                )
            } else {
                merged[key] = GroceryItem(
                    id: ingredient.id,
                    name: ingredient.name,
                    quantity: ingredient.quantity,
                    category: ingredient.category
                )
            }
        }

        return GroceryCategory.allCases.compactMap { category in
            let items = merged.values
                .filter { $0.category == category }
                .sorted { $0.name < $1.name }
            return items.isEmpty ? nil : GrocerySection(category: category, items: items)
        }
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' -only-testing:WorkoutAppTests/GroceryListGeneratorTests
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add WorkoutApp/WorkoutApp/Core/GroceryListGenerator.swift WorkoutApp/WorkoutAppTests/GroceryListGeneratorTests.swift
git commit -m "feat: add grocery list generation"
```

---

### Task 6: Add Local App State

**Files:**
- Create: `WorkoutApp/WorkoutApp/Store/LocalAppState.swift`

- [ ] **Step 1: Add local state container**

Create `WorkoutApp/WorkoutApp/Store/LocalAppState.swift`:

```swift
import Foundation
import Observation
import SwiftUI

@Observable
final class LocalAppState {
    private struct Snapshot: Codable {
        var selectedDayOverride: Weekday?
        var setProgress: [SetProgress]
        var selectedMealIDs: Set<String>
        var checkedGroceryItemIDs: Set<String>
        var quickProteinAdds: [Int]
    }

    private let defaults: UserDefaults
    private let storageKey = "workout.localAppState.v1"

    var selectedDayOverride: Weekday? { didSet { save() } }
    var setProgress: [SetProgress] { didSet { save() } }
    var selectedMealIDs: Set<String> { didSet { save() } }
    var checkedGroceryItemIDs: Set<String> { didSet { save() } }
    var quickProteinAdds: [Int] { didSet { save() } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.selectedDayOverride = nil
        self.setProgress = []
        self.selectedMealIDs = []
        self.checkedGroceryItemIDs = []
        self.quickProteinAdds = []
        restore()
    }

    func progress(for exerciseID: String) -> SetProgress {
        if let existing = setProgress.first(where: { $0.exerciseID == exerciseID }) {
            return existing
        }
        return SetProgress(exerciseID: exerciseID)
    }

    func toggleSet(exerciseID: String, setIndex: Int) {
        let index = setProgress.firstIndex { $0.exerciseID == exerciseID }
        if let index {
            if setProgress[index].completedSets.contains(setIndex) {
                setProgress[index].completedSets.remove(setIndex)
            } else {
                setProgress[index].completedSets.insert(setIndex)
            }
        } else {
            setProgress.append(SetProgress(exerciseID: exerciseID, completedSets: [setIndex]))
        }
    }

    func selectedMeals(from templates: [MealTemplate]) -> [MealTemplate] {
        templates.filter { selectedMealIDs.contains($0.id) }
    }

    private func restore() {
        guard let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return
        }
        selectedDayOverride = snapshot.selectedDayOverride
        setProgress = snapshot.setProgress
        selectedMealIDs = snapshot.selectedMealIDs
        checkedGroceryItemIDs = snapshot.checkedGroceryItemIDs
        quickProteinAdds = snapshot.quickProteinAdds
    }

    private func save() {
        let snapshot = Snapshot(
            selectedDayOverride: selectedDayOverride,
            setProgress: setProgress,
            selectedMealIDs: selectedMealIDs,
            checkedGroceryItemIDs: checkedGroceryItemIDs,
            quickProteinAdds: quickProteinAdds
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
```

- [ ] **Step 2: Build**

Run:

```bash
cd WorkoutApp
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' build
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add WorkoutApp/WorkoutApp/Store/LocalAppState.swift
git commit -m "feat: add local app state"
```

---

### Task 7: Build Today Screen

**Files:**
- Create: `WorkoutApp/WorkoutApp/Design/AppTheme.swift`
- Create: `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift`
- Create: `WorkoutApp/WorkoutApp/Features/Today/ExerciseCardView.swift`
- Modify: `WorkoutApp/WorkoutApp/App/RootTabView.swift`

- [ ] **Step 1: Add theme**

Create `WorkoutApp/WorkoutApp/Design/AppTheme.swift`:

```swift
import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.478, green: 0.184, blue: 0.309)
    static let accentSoft = Color(red: 0.957, green: 0.894, blue: 0.925)
    static let cream = Color(red: 0.984, green: 0.973, blue: 0.961)
}
```

- [ ] **Step 2: Add exercise card**

Create `WorkoutApp/WorkoutApp/Features/Today/ExerciseCardView.swift`:

```swift
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
```

- [ ] **Step 3: Add Today view**

Create `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift`:

```swift
import SwiftUI

struct TodayView: View {
    @Bindable var state: LocalAppState
    private let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let workout = planner.workout(for: currentWeekday(), override: state.selectedDayOverride) ?? ProgramSeed.weeklySchedule[1]
                    header(for: workout)

                    if workout.isRestDay {
                        restCard(for: workout)
                    } else {
                        let active = planner.activeExercise(in: workout, progress: state.setProgress)
                        ForEach(workout.exercises) { exercise in
                            ExerciseCardView(exercise: exercise, isActive: exercise.id == active?.id, state: state)
                        }
                    }
                }
                .padding()
            }
            .background(AppTheme.cream)
            .navigationTitle("Today")
        }
    }

    private func header(for workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(workout.focus.uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.accent)
            Text(workout.name)
                .font(.largeTitle.bold())
            Text(workout.subtitle)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func restCard(for workout: WorkoutDay) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recovery day").font(.title2.bold())
            Text(workout.subtitle)
            Text("Recovery is when the body rebuilds. Today is part of the plan.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func currentWeekday() -> Weekday {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return Weekday.allCases[weekday - 1]
    }
}
```

- [ ] **Step 4: Wire Today into tabs**

Replace `WorkoutApp/WorkoutApp/App/RootTabView.swift`:

```swift
import SwiftUI

struct RootTabView: View {
    @State private var state = LocalAppState()

    var body: some View {
        TabView {
            TodayView(state: state)
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            Text("Food")
                .tabItem { Label("Food", systemImage: "fork.knife") }

            Text("Grocery")
                .tabItem { Label("Grocery", systemImage: "cart") }

            Text("Plan")
                .tabItem { Label("Plan", systemImage: "book") }
        }
        .tint(AppTheme.accent)
    }
}
```

- [ ] **Step 5: Build**

Run:

```bash
cd WorkoutApp
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' build
```

Expected: build succeeds.

- [ ] **Step 6: Commit**

```bash
git add WorkoutApp/WorkoutApp/Design WorkoutApp/WorkoutApp/Features/Today WorkoutApp/WorkoutApp/App/RootTabView.swift
git commit -m "feat: add today workout screen"
```

---

### Task 8: Build Food And Grocery Screens

**Files:**
- Create: `WorkoutApp/WorkoutApp/Features/Food/FoodView.swift`
- Create: `WorkoutApp/WorkoutApp/Features/Grocery/GroceryView.swift`
- Modify: `WorkoutApp/WorkoutApp/App/RootTabView.swift`

- [ ] **Step 1: Add Food view**

Create `WorkoutApp/WorkoutApp/Features/Food/FoodView.swift`:

```swift
import SwiftUI

struct FoodView: View {
    @Bindable var state: LocalAppState

    var selectedMeals: [MealTemplate] {
        state.selectedMeals(from: ProgramSeed.mealTemplates)
    }

    var proteinTotal: Int {
        ProteinTracker.totalProtein(meals: selectedMeals, quickAdds: state.quickProteinAdds)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today's protein") {
                    ProgressView(value: ProteinTracker.progress(total: proteinTotal, target: ProgramSeed.nutritionTargets.protein))
                    Text("\(proteinTotal)g / \(ProgramSeed.nutritionTargets.protein)g")
                        .font(.title2.bold())
                    HStack {
                        Button("+25g") { state.quickProteinAdds.append(25) }
                        Button("+35g") { state.quickProteinAdds.append(35) }
                        Button("+12g") { state.quickProteinAdds.append(12) }
                    }
                }

                Section("Targets") {
                    Text("1600 calories")
                    Text("145g protein")
                    Text("50g fat")
                    Text("145g carbs")
                    Text("100 oz water")
                }
            }
            .navigationTitle("Food")
        }
    }
}
```

- [ ] **Step 2: Add Grocery view**

Create `WorkoutApp/WorkoutApp/Features/Grocery/GroceryView.swift`:

```swift
import SwiftUI

struct GroceryView: View {
    @Bindable var state: LocalAppState

    var selectedMeals: [MealTemplate] {
        state.selectedMeals(from: ProgramSeed.mealTemplates)
    }

    var sections: [GrocerySection] {
        GroceryListGenerator.generate(from: selectedMeals)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Pick meals") {
                    ForEach(MealKind.allCases) { kind in
                        let meals = ProgramSeed.mealTemplates.filter { $0.kind == kind }
                        if !meals.isEmpty {
                            DisclosureGroup(kind.rawValue.capitalized) {
                                ForEach(meals) { meal in
                                    Toggle(meal.name, isOn: Binding(
                                        get: { state.selectedMealIDs.contains(meal.id) },
                                        set: { isOn in
                                            if isOn {
                                                state.selectedMealIDs.insert(meal.id)
                                            } else {
                                                state.selectedMealIDs.remove(meal.id)
                                            }
                                        }
                                    ))
                                }
                            }
                        }
                    }
                }

                ForEach(sections) { section in
                    Section(section.category.rawValue) {
                        ForEach(section.items) { item in
                            Toggle("\(item.name) - \(item.quantity)", isOn: Binding(
                                get: { state.checkedGroceryItemIDs.contains(item.id) },
                                set: { isOn in
                                    if isOn {
                                        state.checkedGroceryItemIDs.insert(item.id)
                                    } else {
                                        state.checkedGroceryItemIDs.remove(item.id)
                                    }
                                }
                            ))
                        }
                    }
                }

                Section("Reset") {
                    Button("Start new grocery session", role: .destructive) {
                        state.selectedMealIDs.removeAll()
                        state.checkedGroceryItemIDs.removeAll()
                    }
                }
            }
            .navigationTitle("Grocery")
        }
    }
}
```

- [ ] **Step 3: Wire Food and Grocery into tabs**

Update `WorkoutApp/WorkoutApp/App/RootTabView.swift`:

```swift
import SwiftUI

struct RootTabView: View {
    @State private var state = LocalAppState()

    var body: some View {
        TabView {
            TodayView(state: state)
                .tabItem { Label("Today", systemImage: "figure.strengthtraining.traditional") }

            FoodView(state: state)
                .tabItem { Label("Food", systemImage: "fork.knife") }

            GroceryView(state: state)
                .tabItem { Label("Grocery", systemImage: "cart") }

            Text("Plan")
                .tabItem { Label("Plan", systemImage: "book") }
        }
        .tint(AppTheme.accent)
    }
}
```

- [ ] **Step 4: Build**

Run:

```bash
cd WorkoutApp
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add WorkoutApp/WorkoutApp/Features/Food WorkoutApp/WorkoutApp/Features/Grocery WorkoutApp/WorkoutApp/App/RootTabView.swift
git commit -m "feat: add food and grocery screens"
```

---

### Task 9: Build Plan Reference Screen

**Files:**
- Create: `WorkoutApp/WorkoutApp/Features/Plan/PlanView.swift`
- Modify: `WorkoutApp/WorkoutApp/App/RootTabView.swift`

- [ ] **Step 1: Add Plan view**

Create `WorkoutApp/WorkoutApp/Features/Plan/PlanView.swift`:

```swift
import SwiftUI

struct PlanView: View {
    @State private var searchText = ""

    var exercises: [Exercise] {
        ProgramSeed.weeklySchedule.flatMap(\.exercises)
    }

    var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("12-week structure") {
                    Text("Weeks 1-4: Build the engine")
                    Text("Weeks 5-8: Build the load")
                    Text("Weeks 9-12: Push the limits")
                }

                Section("Weekly schedule") {
                    ForEach(ProgramSeed.weeklySchedule) { day in
                        VStack(alignment: .leading) {
                            Text(day.name).font(.headline)
                            Text(day.focus).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Exercise library") {
                    ForEach(filteredExercises) { exercise in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(exercise.name).font(.headline)
                            Text(exercise.cue).font(.subheadline)
                            if let demoURL = exercise.demoURL {
                                Link("Demo", destination: demoURL)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .navigationTitle("Plan")
        }
    }
}
```

- [ ] **Step 2: Wire Plan into tabs**

Update `WorkoutApp/WorkoutApp/App/RootTabView.swift` so the fourth tab uses `PlanView()`:

```swift
PlanView()
    .tabItem { Label("Plan", systemImage: "book") }
```

- [ ] **Step 3: Build**

Run:

```bash
cd WorkoutApp
xcodebuild -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator' build
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add WorkoutApp/WorkoutApp/Features/Plan WorkoutApp/WorkoutApp/App/RootTabView.swift
git commit -m "feat: add plan reference screen"
```

---

### Task 10: Final Verification And Simulator Run

**Files:**
- Modify only files needed to fix build or test failures found during verification.

- [ ] **Step 1: Run all unit tests**

Run:

```bash
cd WorkoutApp
xcodebuild test -project WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'generic/platform=iOS Simulator'
```

Expected: all tests pass.

- [ ] **Step 2: Configure XcodeBuildMCP defaults**

Use XcodeBuildMCP:

```text
session_show_defaults
session_set_defaults projectPath="/Users/ansoncordeiro/dev/workout/WorkoutApp/WorkoutApp.xcodeproj" scheme="WorkoutApp" simulatorName="iPhone 17" useLatestOS=true
```

If `iPhone 17` is unavailable, use the newest available iPhone simulator from `list_sims`.

- [ ] **Step 3: Build and run in simulator**

Use XcodeBuildMCP:

```text
build_run_sim
```

Expected: app launches to Today without crashing.

- [ ] **Step 4: Smoke test core flows**

In the simulator:

- Today tab shows the current workout or rest day.
- A workout exercise card displays a Demo link.
- Checking all sets for the active exercise advances the expanded exercise.
- Food tab quick-add buttons increase protein total.
- Grocery tab meal selection generates categorized grocery sections.
- Plan tab search filters exercises.

- [ ] **Step 5: Commit verification fixes**

If verification required fixes:

```bash
git add WorkoutApp
git commit -m "fix: complete workout app verification"
```

If no fixes were needed, do not create an empty commit.

---

## Self-Review Notes

- Spec coverage: Today-first SwiftUI app, local-only state, curated YouTube demo entry points, Food tracking, template grocery builder, Plan reference, and test coverage are all mapped to tasks.
- Scope: v1 excludes login, iCloud sync, local bundled videos, custom meals, analytics dashboards, and Apple Watch support.
- Known implementation risk: XcodeGen is not installed in the current environment, so Task 1 installs it with Homebrew before generating the project.
