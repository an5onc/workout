# Plan Personalization Assessment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first personalization flow that collects profile inputs, requires a baseline fitness assessment, assigns beginner/moderate/advanced difficulty, generates a personalized 12-week plan, prompts six-week retests, and shows assessment progress.

**Architecture:** Add typed personalization models in `UserLogModels.swift`, pure scoring/generation logic in `Core/PersonalizationCalculator.swift`, and persistence APIs in `LocalAppState`. UI stays SwiftUI-local: `PersonalizationFlowView` runs as a sheet from Plan, Today shows retest status, and Progress shows assessment history.

**Tech Stack:** Swift 6, SwiftUI, Observation, UserDefaults JSON snapshot, XCTest, XcodeBuildMCP simulator verification.

---

### Task 1: Personalization Models And Persistence

**Files:**
- Modify: `WorkoutApp/WorkoutApp/Models/UserLogModels.swift`
- Modify: `WorkoutApp/WorkoutApp/Store/LocalAppState.swift`
- Modify: `WorkoutApp/WorkoutAppTests/LocalAppStateTests.swift`

- [ ] **Step 1: Write failing persistence tests**

Add tests proving `UserProfile`, `FitnessAssessment`, and `PersonalizedProgram` persist and restore, and that selecting a personalized plan returns generated plan content.

- [ ] **Step 2: Run focused tests to verify failure**

Run: XcodeBuildMCP `test_sim` with `-only-testing:WorkoutAppTests/LocalAppStateTests/testPersonalizationProfileAssessmentAndProgramPersist`.

Expected: fail because personalization models and state properties do not exist.

- [ ] **Step 3: Add models and state**

Add enums `TrainingLevel`, `AssessmentPhase`, `PushUpVariation`, `MileTestStyle`, model structs `UserProfile`, `FitnessAssessment`, and `PersonalizedProgram`. Add `userProfile`, `fitnessAssessments`, and `personalizedPrograms` to `LocalAppState.Snapshot` and public state.

- [ ] **Step 4: Run focused tests to verify pass**

Expected: personalization persistence tests pass.

### Task 2: Assessment Scoring And Plan Generation

**Files:**
- Create: `WorkoutApp/WorkoutApp/Core/PersonalizationCalculator.swift`
- Modify: `WorkoutApp/WorkoutApp.xcodeproj/project.pbxproj`
- Create: `WorkoutApp/WorkoutAppTests/PersonalizationCalculatorTests.swift`

- [ ] **Step 1: Write failing calculator tests**

Add tests for beginner/moderate/advanced sample results, injury/limitation downshift, generated plan volume changes by level, and retest due dates at week 6 and week 12.

- [ ] **Step 2: Run focused tests to verify failure**

Run: XcodeBuildMCP `test_sim` with `-only-testing:WorkoutAppTests/PersonalizationCalculatorTests`.

Expected: fail because `PersonalizationCalculator` does not exist.

- [ ] **Step 3: Add calculator**

Implement:
- `level(for profile:assessment:)`
- `personalizedProgram(base:profile:assessment:startDate:)`
- `isRetestDue(program:assessments:on:)`
- `nextRetestPhase(program:assessments:on:)`

- [ ] **Step 4: Run focused tests to verify pass**

Expected: calculator tests pass.

### Task 3: Personalization Flow UI

**Files:**
- Create: `WorkoutApp/WorkoutApp/Features/Plan/PersonalizationFlowView.swift`
- Modify: `WorkoutApp/WorkoutApp/Features/Plan/PlanView.swift`
- Modify: `WorkoutApp/WorkoutApp.xcodeproj/project.pbxproj`
- Modify: `WorkoutApp/WorkoutAppTests/WorkoutAppScaffoldTests.swift`

- [ ] **Step 1: Write failing source guard tests**

Add source guards for `PersonalizationFlowView`, `Personalize plan`, `Baseline assessment`, `Push-up test`, `Step test`, `1-mile treadmill`, and `finalizePersonalizedProgram`.

- [ ] **Step 2: Run focused tests to verify failure**

Expected: fail because the view and Plan wiring do not exist.

- [ ] **Step 3: Add view and Plan sheet wiring**

Add a single Form-based sheet. It collects profile basics and assessment entries, computes a level preview, and finalizes the selected preview plan.

- [ ] **Step 4: Run focused tests to verify pass**

Expected: source guards pass and app compiles.

### Task 4: Retest Prompt And Progress History

**Files:**
- Modify: `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift`
- Modify: `WorkoutApp/WorkoutApp/App/RootTabView.swift`
- Modify: `WorkoutApp/WorkoutAppTests/WorkoutAppScaffoldTests.swift`

- [ ] **Step 1: Write failing source guard tests**

Add guards for Today `retestPromptSection`, Progress `assessmentProgressSection`, and assessment metrics labels.

- [ ] **Step 2: Run focused tests to verify failure**

Expected: fail because Today and Progress do not expose assessment state.

- [ ] **Step 3: Add Today and Progress surfaces**

Today shows current training level and week-6/week-12 retest prompt when due. Progress shows push-up reps, step-test steps/recovery, one-mile time, and level history.

- [ ] **Step 4: Run focused tests to verify pass**

Expected: source guards pass and app compiles.

### Task 5: Full Verification And Handoff

**Files:**
- Modify: `.sessions/SESSION_INDEX.md`
- Create: `.sessions/2026-05-24__session-05.md`

- [ ] **Step 1: Run full tests**

Run: XcodeBuildMCP full `test_sim` on the configured simulator.

Expected: all tests pass.

- [ ] **Step 2: Run app**

Run: XcodeBuildMCP `build_run_sim`.

Expected: app builds and launches.

- [ ] **Step 3: Manual simulator spot check**

Open Plan and verify the personalization sheet launches. Verify Today/Progress still render.

- [ ] **Step 4: Update handoff**

Add session 05 with files changed, verification, blockers, and next task.

- [ ] **Step 5: Leave uncommitted unless Anson explicitly asks**

Project rules say not to commit unless explicitly requested.
