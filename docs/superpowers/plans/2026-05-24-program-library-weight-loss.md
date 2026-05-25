# Program Library + Weight Loss Plan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a selectable in-app program library and a second Weight Loss Foundation plan.

**Architecture:** Introduce a `TrainingProgram` seed model that owns each plan's schedule, nutrition targets, meals, and quick protein anchors. Persist `selectedProgramID` in `LocalAppState`, then update Today, Food, Grocery, and Plan to read from the selected program.

**Tech Stack:** Swift 6, SwiftUI, Observation, XCTest, local UserDefaults JSON snapshot.

---

## Files

- Modify `WorkoutApp/WorkoutApp/Models/ProgramModels.swift` to add `TrainingProgram`.
- Modify `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift` to expose multiple programs and the new weight-loss plan.
- Modify `WorkoutApp/WorkoutApp/Store/LocalAppState.swift` to persist selected program id.
- Modify `WorkoutApp/WorkoutApp/Features/Today/TodayView.swift` to use selected program schedule.
- Modify `WorkoutApp/WorkoutApp/Features/Food/FoodView.swift` to use selected program nutrition content.
- Modify `WorkoutApp/WorkoutApp/Features/Grocery/GroceryView.swift` to use selected program meal templates.
- Modify `WorkoutApp/WorkoutApp/Features/Plan/PlanView.swift` to show the selector and selected-program references.
- Modify tests under `WorkoutApp/WorkoutAppTests`.

## Tasks

- [ ] Add failing tests for the program library seed data.
- [ ] Add failing tests for persisted selected program state.
- [ ] Add failing tests for clearing Grocery session state when switching plans.
- [ ] Add source guard tests for selected-program view wiring.
- [ ] Implement `TrainingProgram`, seed program helpers, and the Weight Loss Foundation plan.
- [ ] Persist selected program id and selected-program lookup in `LocalAppState`.
- [ ] Route Plan selector changes through `LocalAppState.selectProgram(id:)`.
- [ ] Wire Today, Food, Grocery, and Plan to selected program content.
- [ ] Run focused tests after each implementation slice.
- [ ] Run the full simulator test suite.
- [ ] Update `.sessions/` handoff with changes and verification.
