# Adaptive Training Engine Design

## Goal

Turn physical training test results into real workout changes, not just a beginner/moderate/advanced label.

## Current Gap

The app currently adjusts set volume from the assigned level and updates the plan after a week-6 retest. It does not yet handpick exercises based on the user's assessment weaknesses.

## V1 Design

Add an adaptive training layer to personalization:

- Score the same tests already collected:
  - push-ups before exhaustion,
  - 3-minute step test,
  - 1-mile treadmill test at 0.0 incline,
  - difficulty ratings and limitations.
- Convert those results into training focuses:
  - push-strength base,
  - aerobic base,
  - conditioning tolerance,
  - joint-friendly loading,
  - advanced progression.
- Tag exercises with simple metadata such as push strength, lower strength, conditioning, treadmill, low impact, and beginner friendly.
- When generating a personalized program, adapt the selected seed plan by:
  - swapping push work toward push-up practice when push-up capacity is low,
  - swapping conditioning work toward repeatable treadmill walk intervals when aerobic scores are low,
  - choosing lower-impact/stable options when difficulty or limitations suggest a recovery risk,
  - progressing conditioning and push work when retests show advanced readiness.

## Scope

This is local-only deterministic logic. It does not add AI calls, accounts, remote services, or a large exercise database.

## Data Flow

1. `PersonalizationFlowView` or `RetestFlowView` collects assessment results.
2. `LocalAppState` normalizes and stores the assessment.
3. `PersonalizationCalculator.personalizedProgram(...)` computes level and adaptation focuses.
4. The generated `TrainingProgram` gets:
   - adjusted volume,
   - adapted exercise choices,
   - weekly-structure notes that explain the training focus.
5. `selectedProgram` surfaces the generated adaptive program everywhere else.

## Exercise Adaptation Rules

- Low push-up capacity:
  - Replace push-strength exercise slots with incline push-up practice.
  - Keep sets conservative and cue clean reps before exhaustion.
- Moderate push-up capacity:
  - Keep normal push-strength work unless the plan already has bodyweight push-up progressions.
- Advanced push-up capacity:
  - Add push-up progression work for push-strength slots where it fits the plan.
- Low step-test or slow mile:
  - Replace conditioning finishers with treadmill walk intervals.
  - Add weekly-structure focus text for aerobic base.
- Advanced aerobic readiness:
  - Use treadmill run/walk intervals instead of generic easy finishers.
- High difficulty or limitations:
  - Prefer stable lower-body exercises such as box squats, supported split squats, or leg press.
  - Prefer low-impact conditioning.

## Testing

- Calculator tests must prove weak push/aerobic results change exercise selection.
- Calculator tests must prove advanced retest results progress future exercise choices.
- Store tests must prove a week-6 retest updates the generated program with the new adaptive choices.
- Full simulator tests remain the main regression check.

## Risks

- This is rule-based and should be tuned after real users complete assessments.
- Exercise tags are intentionally small in V1; a future exercise library can expand them without changing the app architecture.
