# Gym Flow v3 Design

## Goal

Build the next local-only gym workflow around the features most likely to matter during an actual workout: exercise substitutions when equipment is taken, a clear end-of-workout summary, exercise history details, and weekly adherence visibility.

## Scope

This slice keeps the 70/30 priority split: performance tracking and in-gym flow first, body composition only as supporting context. It does not add accounts, sync, coaching chat, Apple Health, grocery expansion, or remote video hosting.

## Features

### Machine-Taken Substitutions

Each exercise can expose two or three substitutions with names, equipment, target, cues, and demo links. The Today screen shows these inside the expanded exercise card so she can quickly choose an alternative without leaving the workout flow. The app records the selected substitution locally for that exercise and date.

### Workout Finish Summary

Today gets a compact finish panel after workout exercises. It shows completed sets, logged volume, and remaining sets for the selected day. It also provides a local "Mark workout finished" action so the Progress screen can distinguish partial logging from a completed workout.

### Exercise History Detail

Progress adds exercise-specific history from local workout logs: best set, recent sessions, and simple text trend summaries. The goal is to answer "what did I do last time?" and "am I improving?" without complex charting.

### Program Calendar and Adherence

Progress adds a weekly adherence section showing recent workout days, whether they were completed, and how many sets were logged. This should make consistency obvious without becoming a social or gamified product.

## Architecture

The app stays SwiftUI-native with `LocalAppState` as the root local store. New data remains Codable and stored in the existing UserDefaults snapshot. Program substitutions live in `ProgramSeed` alongside exercise definitions, while derived summaries live in `WorkoutPlanner` so UI views stay thin.

## Data Model

- `ExerciseSubstitution`: static plan metadata for alternative movements.
- `Exercise.substitutions`: static alternatives for each exercise.
- `WorkoutLog.finishedAt`: optional marker that the user finished that day.
- `WorkoutLog.selectedSubstitutionIDs`: per-exercise chosen substitution for that date.
- `WorkoutSummary`: derived counts and volume for one workout/day.

## Testing

Tests cover static seed quality, summary calculations, local persistence, substitution selection, and finish tracking. UI remains verified by simulator build/run after the behavior tests pass.

## Constraints

Existing Xcode project signing changes must be preserved. Avoid project regeneration. Keep edits in current files unless a new file is worth manually wiring into the project.
