# Adaptive Training Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make baseline and week-6 physical training test results handpick future workout exercises.

**Architecture:** Add small exercise tags to the existing `Exercise` model and keep adaptation deterministic inside `PersonalizationCalculator`. `LocalAppState` already regenerates personalized programs after baseline and retest, so the adaptive schedule flows through existing selected-program state.

**Tech Stack:** Swift 6, SwiftUI, XCTest, local `UserDefaults` persistence.

---

## File Structure

- Modify `WorkoutApp/WorkoutApp/Models/ProgramModels.swift` for `ExerciseTag` and tagged exercises.
- Modify `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift` to tag seed exercises.
- Modify `WorkoutApp/WorkoutApp/Core/PersonalizationCalculator.swift` to compute focuses and swap exercises.
- Modify `WorkoutApp/WorkoutApp/Store/LocalAppState.swift` only if retest regeneration needs adjustment.
- Modify `WorkoutApp/WorkoutAppTests/PersonalizationCalculatorTests.swift` for adaptive exercise tests.
- Modify `WorkoutApp/WorkoutAppTests/LocalAppStateTests.swift` for week-6 adaptive retest persistence.
- Update session handoff after verification.

## Tasks

### Task 1: Exercise Tags

- [ ] Write failing tests that expect generated weak-push programs to contain handpicked push work.
- [ ] Add `ExerciseTag` and `tags` to `Exercise`.
- [ ] Preserve existing exercise construction by defaulting tags to an empty set.
- [ ] Tag seed plan exercises through the `ProgramSeed.exercise(...)` helper.

### Task 2: Adaptive Exercise Selection

- [ ] Add assessment-focus helpers in `PersonalizationCalculator`.
- [ ] Swap push-strength slots to incline push-up practice for low push-up results.
- [ ] Swap conditioning slots to treadmill walk intervals for low step-test or slow-mile results.
- [ ] Swap higher-risk lower-body slots to stable alternatives when limitations or high difficulty are present.
- [ ] Progress push/conditioning slots for advanced retests.

### Task 3: Retest Regeneration

- [ ] Add a failing store test proving week-6 retest changes future exercise names.
- [ ] Ensure `recordFitnessRetest(...)` continues to regenerate from the base seed plan with the latest assessment.
- [ ] Preserve baseline assessment ID and latest assessment ID.

### Task 4: Verification And Handoff

- [ ] Run focused adaptive calculator/store tests.
- [ ] Run full XcodeBuildMCP simulator tests.
- [ ] Run simulator build/run.
- [ ] Run `git diff --check`.
- [ ] Update `.sessions/SESSION_INDEX.md` and add the latest session file.

## Self-Review

- The plan covers the user requirement to adjust future exercises based on test results.
- No backend, AI, or large exercise database is included.
- The implementation stays within existing personalization and seed-program boundaries.
