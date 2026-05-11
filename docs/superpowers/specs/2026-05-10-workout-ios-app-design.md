# Workout iOS App Design

## Context

This project contains a 12-week workout and nutrition plan in `12_Week_Plan.docx` and an existing mobile-oriented HTML companion in `daily_companion.html`. The iOS app should turn that plan into a native, personal, local-only iPhone app that is useful in two real contexts:

- At the gym, while actively working through a workout and needing quick exercise cues or demo videos.
- At the grocery store, while choosing plan meals and buying the right ingredients.

The selected v1 direction is a native SwiftUI app, not a web wrapper. The app will use curated YouTube links for exercise demos in v1.

## Product Shape

The app is a personal, local-only SwiftUI iPhone app. It has no login, no account system, and no iCloud sync in v1. All personal progress data stays on the phone.

Main tabs:

- **Today**: default launch screen. Shows today's workout or rest day. The first or current exercise is expanded by default, with set logging, weight/reps entry, cues, and a Demo button.
- **Food**: daily protein tracker, nutrition targets, selected meals, and quick-add protein anchors.
- **Grocery**: template-based meal picker from the plan's meal options, generating a categorized grocery list.
- **Plan**: full 12-week schedule, exercise library, nutrition reference, and mindset/toolkit content.

The primary product choice is "Today-first companion." The app should optimize for the gym moment before analytics or broad reference browsing.

## Data Model And Persistence

The app will use a small local Swift data layer. SwiftData is preferred if the generated Xcode target supports it cleanly. A lightweight JSON/UserDefaults fallback is acceptable for seed data and simple settings.

Core model groups:

- **Program seed data**: phases, weeks, days, workouts, exercises, cues, mistakes, feel targets, rest times, rep ranges, meal templates, grocery ingredients, grocery categories, mindset cards, and nutrition targets. This content is bundled with the app and derived from the plan.
- **Workout logs**: date, selected workout day, exercise id, set number, completed state, weight, reps, optional RPE, and notes.
- **Food logs**: date, protein total, checked meal templates, quick-add entries, and optional water progress.
- **Grocery sessions**: selected meal templates for the week, generated ingredient list, checked items, and reset state.
- **Check-ins**: weekly weight, waist, hips, notes, and optional progress-photo references later.

Important persistence behavior:

- The 12-week plan content is read-only seed data.
- Logs are date-based, so today's work does not overwrite past days.
- The app infers the current weekday workout, but the user can manually switch days.
- Manual day overrides affect the current session without corrupting date-based logs.

## Screen Behavior

### Today

The app launches to Today. It shows the weekday workout or rest day.

Workout-day behavior:

- Header shows workout name, focus, phase/week, approximate duration, and total sets.
- The active exercise card is expanded by default.
- The expanded exercise includes set buttons, weight/reps fields, rest timer shortcut, form cues, mistakes to avoid, feel target, and Demo button.
- Upcoming exercises appear collapsed below the active card.
- When all sets for the active exercise are checked, the next exercise expands automatically.
- The user can manually expand or collapse any exercise.

Rest-day behavior:

- Thursday shows full rest guidance and optional walking.
- Sunday shows rest plus meal-prep guidance.

### Food

Food supports fast daily tracking rather than full calorie accounting.

- Protein target is 145g/day.
- Daily nutrition targets are shown compactly: 1600 calories, 145g protein, 50g fat, 145g carbs, 100 oz water.
- Meal templates come from the plan.
- Quick-add protein anchors include whey, Greek yogurt, chicken, eggs, tuna, and similar plan items.
- Checked meals and quick-add entries contribute to the day's protein total.

### Grocery

The selected v1 grocery mode is a template picker.

- The user picks breakfasts, lunches, dinners, and snacks from the plan's existing meal options.
- The app generates a grocery list from those selections.
- Grocery items are grouped by Produce, Meat & Seafood, Dairy & Eggs, Pantry, and Supplements & Extras.
- Duplicate ingredients are merged where practical.
- Items are checkable.
- Reset starts a new grocery session.
- Sunday prep instructions are available below the generated list.

### Plan

Plan is the reference area.

- 12-week structure and phase descriptions.
- Weekly schedule.
- Exercise library with search and Demo links.
- Nutrition reference, grocery reference, Sunday prep instructions.
- Mindset toolkit and gym-anxiety cards.

## Exercise Demos

Exercise demos use curated YouTube links in v1.

Behavior:

- Each exercise can have an optional demo URL.
- Tapping Demo opens the link in an in-app browser or external YouTube/Safari flow, depending on the cleanest SwiftUI implementation.
- If an exercise has no demo URL, the Demo button is hidden or disabled with a short "Demo coming soon" state.

The data model should allow local bundled videos later without changing the Today screen contract.

## Architecture

The app should use a feature-based SwiftUI structure:

- `Models`: seed entities and log entities.
- `ProgramData`: bundled 12-week workout, exercise, meal, grocery, and mindset content.
- `Store`: local persistence and query helpers.
- `Features/Today`: workout flow and exercise logging.
- `Features/Food`: protein and meal tracking.
- `Features/Grocery`: meal template picker and generated grocery list.
- `Features/Plan`: searchable reference library.
- `Tests`: model and generation logic.

Seed content should be structured data, not hardcoded into views. Views should consume typed models so the same exercise and meal definitions can power Today, Plan, Food, and Grocery.

## Error Handling

- If a YouTube demo link is missing, hide or disable Demo with "Demo coming soon."
- If today's workout cannot be inferred, fall back to manual day selection.
- If grocery generation finds an ingredient without a category, place it under Other.
- If local persistence fails, preserve the current in-memory session and show a low-friction message instead of clearing the workout screen.
- If seed data fails to load, show a recoverable empty-state message rather than crashing.

## Testing

Initial tests should cover pure model and generation behavior:

- Monday, Saturday, Thursday, and Sunday workout lookup.
- Active exercise auto-advance after all sets are complete.
- Manual day override behavior.
- Protein totals from checked meals and quick-add entries.
- Grocery generation from selected meal templates.
- Grocery category grouping.
- Duplicate grocery ingredient merging.
- Missing demo URL behavior.

UI testing can follow once the core flows are implemented, with emphasis on the Today tab and Grocery generation flow.

## Out Of Scope For V1

- Login or accounts.
- iCloud sync.
- Fully custom user-created meals.
- Analytics-heavy dashboards.
- Local bundled exercise videos.
- Calorie/macronutrient database search.
- Apple Watch support.

These can be added later if the v1 gym and grocery workflows prove useful.
