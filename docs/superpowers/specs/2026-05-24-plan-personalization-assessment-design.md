# Plan Personalization and Fitness Assessment Design

## Goal

Add a required personalization flow before a user starts a plan. The app should collect basic profile inputs and a repeatable physical training assessment, then use those results to assign a beginner, moderate, or advanced version of the selected 12-week plan. The same assessment repeats every six weeks so the user can see progress and the app can adjust the next training block.

## User Flow

1. User selects a plan goal from the existing Plan tab chooser.
2. App opens a personalization flow before the plan is finalized.
3. User enters profile inputs:
   - age
   - height
   - weight
   - training experience
   - available workout days per week
   - injuries or movement limitations
4. User completes the baseline physical training test.
5. App calculates an assessment level: beginner, moderate, or advanced.
6. App finalizes a personalized 12-week plan using the selected base plan and assessment level.
7. App schedules retests at week 6 and week 12.
8. After the week-6 retest, app shows progress and adjusts weeks 7-12 if the level changed.

## Physical Training Test

The assessment has three required tests. These should be performed before starting exercises, then repeated at week 6 and week 12.

### Push-Up Test

- Test: maximum push-ups before technical exhaustion.
- User records total reps.
- User records variation:
  - standard
  - knee
  - incline
- Stop condition: form breaks or the user cannot complete another clean rep.

### Step Test

- Test: timed step test.
- Recommended duration: 3 minutes.
- User records:
  - completed test: yes/no
  - total steps completed
  - optional 1-minute recovery heart rate
  - perceived difficulty, 1-10
- The timed format is the source of truth because it gives a consistent workload every six weeks. Step count can be tracked as a secondary score.

### 1-Mile Treadmill Test

- Test: 1-mile walk/run on treadmill.
- Incline: 0.0.
- User records:
  - completion time
  - walk, run, or walk/run style
  - optional average heart rate
  - perceived difficulty, 1-10

## Level Assignment

The app should use assessment results as the primary level signal. Age, height, weight, experience, and limitations should shape the plan, but should not override the actual physical test unless safety requires it.

### Beginner

- Lower starting volume.
- Longer rests.
- Simpler exercise variations.
- Lower conditioning intensity.
- More mobility/recovery emphasis.

### Moderate

- Standard plan volume.
- Balanced strength and conditioning.
- Normal rest periods.
- Main exercise variations from the selected plan.

### Advanced

- Higher volume or added sets.
- Shorter rests where appropriate.
- Harder exercise variations.
- More challenging conditioning finishers.

## Plan Generation Rules

- Keep the existing seeded programs as base templates.
- Generate a personalized program from:
  - selected base program id
  - user profile
  - latest assessment result
  - assigned training level
- Preserve the existing 12-week framing.
- Weeks 1-6 use the baseline assessment level.
- Week 6 retest can adjust weeks 7-12:
  - if results improve clearly, increase difficulty one level or add progression.
  - if results decline or difficulty is high, maintain or reduce difficulty.
  - if results are mixed, keep the same level and adjust only weak areas.

## Data Model

Add durable local models:

- `UserProfile`
  - age
  - height
  - weight
  - experience level
  - available days per week
  - limitations

- `FitnessAssessment`
  - id
  - date
  - phase: baseline, week6, week12
  - push-up reps
  - push-up variation
  - step-test duration
  - step count
  - recovery heart rate
  - step-test difficulty
  - one-mile time
  - one-mile style
  - one-mile difficulty
  - computed level

- `PersonalizedProgram`
  - base program id
  - assigned level
  - generated nutrition targets
  - generated weekly schedule
  - baseline assessment id
  - latest assessment id
  - start date

Store these in the existing `LocalAppState` UserDefaults snapshot. No backend is needed.

## UI Surfaces

### Plan Tab

- Add `Personalize plan` from selected plan preview.
- If a plan is already personalized, show:
  - current assigned level
  - baseline date
  - next retest date
  - latest assessment trend

### Personalization Flow

- Step 1: profile basics.
- Step 2: assessment instructions.
- Step 3: push-up result entry.
- Step 4: timed step-test result entry.
- Step 5: 1-mile treadmill result entry.
- Step 6: results summary and assigned level.
- Step 7: finalize plan.

### Today Tab

- Show current personalized level in the Goal card.
- Show week-6 retest prompt when due.

### Progress Tab

- Add an Assessment Progress section:
  - push-up reps over time
  - step-test steps and recovery heart rate over time
  - 1-mile time over time
  - assigned level changes

## Safety And Validation

- The app should frame the assessment as self-paced and stop-on-symptoms.
- Required validation:
  - age must be a reasonable positive number.
  - height and weight must be positive.
  - push-up reps cannot be negative.
  - step-test duration should default to 3 minutes.
  - 1-mile time must be positive if the test is completed.
- Injury/limitation answers should bias the level down or trigger lower-impact substitutions.

## Testing

Add focused tests for:

- profile persistence and restore.
- assessment persistence and restore.
- level calculation for beginner, moderate, and advanced sample results.
- generated plan volume differs by level.
- week-6 retest due-date detection.
- week-6 reassessment can adjust weeks 7-12.
- source guards that Plan, Today, and Progress expose the new personalization surfaces.

## Implementation Phases

1. Add models and pure assessment calculator.
2. Add persistence to `LocalAppState`.
3. Add personalization flow UI.
4. Generate level-adjusted plan variants from seeded plans.
5. Add Today retest prompts.
6. Add Progress assessment history.
7. Run full simulator tests and manual UI verification.

## Open Follow-Up

- Decide the exact scoring thresholds for beginner, moderate, and advanced. These should be conservative in V1 and easy to tune after real user testing.
