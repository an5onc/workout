# Program Library + Weight Loss Plan Design

## Goal

Add the app framework for multiple workout plans and ship a second selectable plan focused on weight loss.

## Product Direction

The app currently behaves as if there is only one plan: a lower-body muscular resistance plan aimed at building muscle while burning fat. The next version should let the user choose the plan that best fits her current goal without adding accounts, onboarding, sync, or a backend.

The first selectable plans are:

- **Lower Body Strength + Recomp**: the existing 12-week lower-body and resistance plan.
- **Weight Loss Foundation**: a lighter, conditioning-forward plan built around full-body strength, incline walking/cardio, core, mobility, and high-protein nutrition targets.

## User Experience

The Plan tab becomes the place to choose a plan. At the top, it shows a current-plan card and a list of available plans. Each plan shows its goal, short description, weekly structure, and a `Use this plan` action. Today shows a compact current-plan label so the user can tell which program is active before logging.

Changing plans affects what the app shows going forward:

- Today uses the selected plan's weekly schedule.
- Prep Ahead resolves future workouts from the selected plan.
- Food uses the selected plan's nutrition targets, meal templates, and quick protein anchors.
- Grocery uses the selected plan's meal templates.
- Plan reference shows the selected plan's schedule, exercise library, nutrition reference, grocery reference, and prep notes.

Existing logs remain date-based and are not deleted or migrated when the selected plan changes.

Switching plans clears the current Grocery meal selections and checked grocery items. This prevents ingredients from the previous plan from silently carrying into the new plan's grocery workflow.

## Architecture

Add a `TrainingProgram` model that packages all plan-specific content:

- id, name, goal, description
- structure summary and prep notes
- weekly schedule
- nutrition targets
- meal templates
- quick protein anchors

`ProgramSeed` exposes `programs`, `defaultProgramID`, `defaultProgram`, and helpers for resolving a program by id. The existing static seed content becomes the default program. The new weight-loss plan is a second static seed program.

`LocalAppState` persists `selectedProgramID` inside the existing UserDefaults snapshot. If stored data is missing or references a removed program id, the app falls back to `ProgramSeed.defaultProgramID`.

Views receive the selected program from `LocalAppState` and avoid reading global `ProgramSeed.weeklySchedule`, `ProgramSeed.mealTemplates`, or `ProgramSeed.nutritionTargets` directly except for fallback/testing helpers.

## Weight Loss Foundation Plan

The weight-loss plan should be approachable and sustainable:

- 3 full-body strength days.
- 2 low-impact conditioning days built around incline walking, bike, elliptical, or rower.
- 1 mobility/core day.
- 1 rest and prep day.

Strength workouts use moderate sets, controlled tempo, short rests, and mostly machine/dumbbell movements. Conditioning days are logged as exercises with duration-style rep ranges so they fit the current workout-card framework.

Nutrition targets should support weight loss while preserving lean mass. Use a lower calorie target than the current plan, keep protein high, and include simple meal templates that drive Food and Grocery.

## Testing

Add or update XCTest coverage for:

- Two programs exist with unique IDs.
- Default program preserves the current plan identity and Monday workout.
- Weight Loss Foundation exists and has seven scheduled days.
- `LocalAppState` defaults to the current plan and persists selected program id.
- Invalid stored program ids fall back to the default program.
- Switching to a different program clears Grocery session state.
- Selecting the current program leaves Grocery session state unchanged.
- Food/Grocery/Plan source guards use selected program content instead of global seed arrays.

Run the full simulator test suite after implementation.

## Out Of Scope

- First-run onboarding.
- Accounts, sync, backend personalization, AI coaching, or remote plan downloads.
- Migrating old logs when switching plans.
- A new Programs tab.
- Custom user-created plans.
