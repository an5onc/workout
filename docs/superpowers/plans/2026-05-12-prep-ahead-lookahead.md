# Prep Ahead Lookahead Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a date-based Prep Ahead flow where the user chooses `+1` through `+7` days, previews that future workout, watches demos, and pre-selects substitutions for that future date.

**Architecture:** Keep live workout logging inside `TodayView` and add a separate `PrepAheadView` for future planning. Add a `WorkoutPlanner` date helper so date-to-weekday logic is shared and testable. Reuse existing date-scoped substitution storage in `LocalAppState`.

**Tech Stack:** Swift 6, SwiftUI, Observation, XCTest, local `UserDefaults` persistence.

---

## File Structure

- Modify `WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift`
  - Add a date-based workout resolver.
- Modify `WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift`
  - Add coverage for date-to-weekday workout resolution.
- Modify `WorkoutApp/WorkoutAppTests/LocalAppStateTests.swift`
  - Add coverage proving future-date substitution choices do not affect today's choices.
- Create `WorkoutApp/WorkoutApp/Features/Today/PrepAheadView.swift`
  - Render the future workout preview and substitution controls.
- Modify `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift`
  - Add lookahead offset state, date injection, day chips, and the prep preview.
- Modify `WorkoutApp/WorkoutAppTests/WorkoutAppScaffoldTests.swift`
  - Add source-level checks that Prep Ahead exists and does not expose live completion controls.

---

### Task 1: Date-Based Workout Resolution

**Files:**
- Modify: `WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift`
- Test: `WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift`

- [ ] **Step 1: Write the failing planner test**

Add this test to `WorkoutPlannerTests` after `testWeekdayLookupFallsBackToCurrentDay`:

```swift
func testDateLookupUsesDateWeekday() throws {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let monday = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 11, hour: 12).date!
    let saturday = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 5, day: 16, hour: 12).date!
    let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)

    XCTAssertEqual(planner.workout(for: monday, calendar: calendar)?.name, "Lower A")
    XCTAssertEqual(planner.workout(for: saturday, calendar: calendar)?.name, "Lower C")
}
```

- [ ] **Step 2: Run the failing test**

Run:

```bash
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WorkoutAppTests/WorkoutPlannerTests/testDateLookupUsesDateWeekday
```

Expected: build fails because `WorkoutPlanner.workout(for:calendar:)` does not exist.

- [ ] **Step 3: Implement the date resolver**

Add this method to `WorkoutPlanner` below the existing `workout(for currentDay:override:)` method:

```swift
func workout(for date: Date, calendar: Calendar = .current) -> WorkoutDay? {
    let weekdayIndex = calendar.component(.weekday, from: date) - 1
    guard Weekday.allCases.indices.contains(weekdayIndex) else {
        return nil
    }
    return schedule.first { $0.id == Weekday.allCases[weekdayIndex] }
}
```

- [ ] **Step 4: Run the planner test**

Run:

```bash
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WorkoutAppTests/WorkoutPlannerTests/testDateLookupUsesDateWeekday
```

Expected: test passes.

- [ ] **Step 5: Commit the planner helper**

Run:

```bash
git add WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift WorkoutApp/WorkoutAppTests/WorkoutPlannerTests.swift
git commit -m "feat: add date-based workout lookup"
```

---

### Task 2: Future-Date Substitution Coverage

**Files:**
- Modify: `WorkoutApp/WorkoutAppTests/LocalAppStateTests.swift`

- [ ] **Step 1: Write the failing/confirming state test**

Add this test after `testSelectedSubstitutionPersistsByDate`:

```swift
func testFutureSubstitutionDoesNotAffectToday() {
    let state = LocalAppState(defaults: defaults)
    let today = date(year: 2026, month: 5, day: 12)
    let future = date(year: 2026, month: 5, day: 13)

    state.selectSubstitution(exerciseID: "db-bench-press", substitutionID: "smith-machine-bench", date: future)

    XCTAssertNil(state.selectedSubstitutionID(exerciseID: "db-bench-press", date: today))
    XCTAssertEqual(state.selectedSubstitutionID(exerciseID: "db-bench-press", date: future), "smith-machine-bench")
}
```

- [ ] **Step 2: Run the state test**

Run:

```bash
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WorkoutAppTests/LocalAppStateTests/testFutureSubstitutionDoesNotAffectToday
```

Expected: test passes with the current date-scoped substitution model. If it fails, inspect `LocalAppState.selectSubstitution(exerciseID:substitutionID:date:)` and `LocalAppState.selectedSubstitutionID(exerciseID:date:)` before changing UI code.

- [ ] **Step 3: Commit the state coverage**

Run:

```bash
git add WorkoutApp/WorkoutAppTests/LocalAppStateTests.swift
git commit -m "test: cover future substitution isolation"
```

---

### Task 3: Prep Ahead View

**Files:**
- Create: `WorkoutApp/WorkoutApp/Features/Today/PrepAheadView.swift`

- [ ] **Step 1: Create the view file**

Create `PrepAheadView.swift` with this implementation:

```swift
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
```

- [ ] **Step 2: Build to catch file-inclusion issues**

Run:

```bash
xcodebuild build -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: build succeeds. If the build fails because `PrepAheadView.swift` is not in the target, add `PrepAheadView.swift` to the `WorkoutApp` target in Xcode, inspect `git diff -- WorkoutApp/WorkoutApp.xcodeproj/project.pbxproj`, and stage only the intentional file-reference changes.

- [ ] **Step 3: Commit the view**

Run:

```bash
git add WorkoutApp/WorkoutApp/Features/Today/PrepAheadView.swift
git commit -m "feat: add prep ahead preview view"
```

If a target-membership project-file change was required, also run `git add WorkoutApp/WorkoutApp.xcodeproj/project.pbxproj` after confirming the diff contains only the `PrepAheadView.swift` target reference.

---

### Task 4: Wire Prep Ahead Into Today

**Files:**
- Modify: `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift`

- [ ] **Step 1: Add date injection and lookahead state**

Change the top of `TodayView` to include a current-date dependency and selected offset:

```swift
struct TodayView: View {
    let state: LocalAppState
    var currentDate: () -> Date = Date.init
    @State private var selectedPrepAheadOffset = 1
    @State private var manuallyExpandedExerciseIDs: Set<String> = []
    @State private var manuallyCollapsedExerciseIDs: Set<String> = []
    @State private var lastActiveExerciseID: String?
    private let planner = WorkoutPlanner(schedule: ProgramSeed.weeklySchedule)
```

- [ ] **Step 2: Render Prep Ahead near the top**

In `body`, place `prepAheadSection` after `brandBanner` and before `header(for: workout)`:

```swift
brandBanner
prepAheadSection
header(for: workout)
```

- [ ] **Step 3: Add the Prep Ahead section helpers**

Add these helpers above `header(for:)`:

```swift
private var prepAheadSection: some View {
    let futureDate = prepAheadDate(offset: selectedPrepAheadOffset)
    let futureWorkout = planner.workout(for: futureDate) ?? ProgramSeed.weeklySchedule[1]

    return VStack(alignment: .leading, spacing: 10) {
        HStack {
            Text("Prep Ahead")
                .font(.headline)
            Spacer()
            Text("+\(selectedPrepAheadOffset)d")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
        }

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { offset in
                    Button {
                        selectedPrepAheadOffset = offset
                    } label: {
                        Text("+\(offset)")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 44, height: 34)
                    }
                    .buttonStyle(.bordered)
                    .tint(offset == selectedPrepAheadOffset ? AppTheme.accent : .secondary)
                }
            }
        }

        PrepAheadView(workout: futureWorkout, futureDate: futureDate, state: state)
    }
}

private func prepAheadDate(offset: Int) -> Date {
    Calendar.current.date(byAdding: .day, value: offset, to: currentDate()) ?? currentDate()
}
```

- [ ] **Step 4: Route current date through existing Today logic**

Replace direct `Date()` usage in `TodayView` with `currentDate()` where the code is referring to today's workout state:

```swift
let log = state.workoutLog(for: currentDate())
```

```swift
state.finishWorkout(date: currentDate())
```

```swift
let weekday = Calendar.current.component(.weekday, from: currentDate())
```

When constructing `ExerciseCardView`, pass the date dependency:

```swift
ExerciseCardView(
    exercise: exercise,
    isExpanded: expansionBinding(for: exercise, activeExerciseID: active?.id),
    state: state,
    currentDate: currentDate
)
```

- [ ] **Step 5: Build**

Run:

```bash
xcodebuild build -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: build succeeds.

- [ ] **Step 6: Commit the Today integration**

Run:

```bash
git add WorkoutApp/WorkoutApp/Features/Today/TodayView.swift
git commit -m "feat: wire prep ahead into today"
```

---

### Task 5: Scaffold Tests And Full Verification

**Files:**
- Modify: `WorkoutApp/WorkoutAppTests/WorkoutAppScaffoldTests.swift`

- [ ] **Step 1: Add source-level UI structure tests**

Add these tests before `sourcePath(_:)`:

```swift
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
}
```

- [ ] **Step 2: Run the scaffold tests**

Run:

```bash
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:WorkoutAppTests/WorkoutAppScaffoldTests
```

Expected: scaffold tests pass.

- [ ] **Step 3: Run the full test suite**

Run:

```bash
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected: all tests pass.

- [ ] **Step 4: Run and visually verify in the simulator**

Run:

```bash
xcodebuild build -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Then use XcodeBuildMCP `build_run_sim` to launch the app on the iPhone 17 simulator. Verify:

- Today shows the brand banner, Prep Ahead, and the live workout.
- `+1` through `+7` chips switch the preview date and workout.
- Rest days show rest guidance.
- Lifting days show exercises, demo links, and substitution menus.
- Selecting a future substitution does not change today's live workout.
- Light mode and dark mode remain readable.

- [ ] **Step 5: Commit the verification tests**

Run:

```bash
git add WorkoutApp/WorkoutAppTests/WorkoutAppScaffoldTests.swift
git commit -m "test: cover prep ahead wiring"
```

---

## Final Verification

Run these before calling the feature complete:

```bash
git diff --check
xcodebuild build -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Expected:

- `git diff --check` prints no output.
- Build succeeds.
- Full test suite passes.
- Manual simulator check confirms readable light and dark mode.
