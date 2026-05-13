# Prep Ahead Lookahead Design

## Goal

Give the user control over how far ahead she wants to prepare for a workout, from 1 to 7 days in the future. The feature should help her study exercises the night before, watch demos, review cues, and pre-select substitutions for a specific future date.

This is a prep feature, not a logging feature. Today remains the place for lifting, tracking sets, running rest timers, and finishing workouts.

## Product Behavior

Add a Prep Ahead entry point in the Today flow. The user can choose a lookahead distance from 1 to 7 days. The selected offset maps to an actual future date, then the app resolves the scheduled workout for that date's weekday.

For the selected future date, the app shows:

- Future date label and workout name.
- Workout focus and subtitle.
- Exercise list with sets, reps, rest, cues, and demo links.
- Substitution choices for each exercise.
- The currently selected substitution for that future date.

The app does not show set logging, finish workout, active exercise advancement, or rest timer controls in Prep Ahead mode.

## Recommended UI

Place a compact Prep Ahead section near the top of Today, below the brand banner and before today's workout detail. Use a horizontal row of seven compact day chips for `+1` through `+7` days. The selected value drives the preview below it.

The preview should feel like a lightweight planning panel, not a second full workout screen. Each exercise uses a compact collapsible card with demo and substitution controls.

If the selected future date is a rest day, show the rest-day prep message and avoid empty exercise controls.

## Data Model

Use actual dates for prep choices. This is important because selecting a substitution for next Tuesday should not permanently alter every Tuesday in the program.

The app already stores substitutions inside `WorkoutLog.selectedSubstitutionIDs` by date. The feature should reuse that model:

- Future date is calculated from today's date plus selected offset.
- `LocalAppState.selectedSubstitutionID(exerciseID:date:)` reads the future-date choice.
- `LocalAppState.selectSubstitution(exerciseID:substitutionID:date:)` writes the future-date choice.

When that future date becomes today, the existing Today flow should automatically pick up those stored substitutions because it reads substitution state by date.

## Components

`TodayView`

- Owns the selected lookahead offset state.
- Calculates the future date.
- Renders the Prep Ahead section.
- Keeps today's workout logging unchanged.

`PrepAheadView`

- Displays the selected future workout.
- Shows demo links, cues, and substitution menus.
- Calls `LocalAppState` with the future date when substitutions change.

`WorkoutPlanner`

- Gets a small helper for resolving a workout from a `Date`, so weekday mapping is not duplicated across views.

## Data Flow

1. User opens Today.
2. App defaults lookahead to `+1 day`.
3. User chooses any offset from `+1` to `+7`.
4. Today calculates `futureDate`.
5. Planner resolves the workout for `futureDate`.
6. Prep Ahead reads substitutions from the workout log for `futureDate`.
7. User selects or clears substitutions.
8. `LocalAppState` saves those selections under the future date's workout log.
9. On that date, Today reads the same date-scoped substitutions during the live workout.

## Edge Cases

- If the selected future day is a rest day, show recovery and prep guidance only.
- If an exercise has no substitutions, show its demo and cues without a substitution menu.
- If a demo URL is missing, show the existing "Demo coming soon" style.
- If the device date changes while the app is open, recalculate future dates on render rather than storing absolute dates in view state.

## Testing

Add focused unit tests for:

- Date-to-weekday workout resolution.
- Future-date substitution storage does not affect today's substitution.
- A future substitution becomes visible when querying that same future date.

Add scaffold/source tests for:

- Today contains a Prep Ahead surface.
- Prep Ahead does not expose live workout completion controls.

Manual verification:

- Launch the app in light and dark mode.
- Switch through `+1` to `+7`.
- Select a substitution for a future workout.
- Confirm Today remains unchanged.
- Simulate or query the future date path and confirm the substitution is available for that date.

## Out Of Scope

- Full calendar planning.
- Editing the workout program.
- Future set logging.
- Notifications or reminders.
- Syncing prep choices across devices.
