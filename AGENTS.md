# AGENTS.md - Workout Project Handoff

## Project

This repo is a local-first iOS workout and nutrition companion app named "I'd Lift That". It turns the source 12-week workout plan into a native SwiftUI app for gym-day logging, prep-ahead review, protein tracking, grocery planning, and plan reference.

The product direction is documented in:

- `docs/superpowers/specs/2026-05-10-workout-ios-app-design.md` - original v1 product and architecture spec.
- `docs/superpowers/specs/2026-05-11-gym-flow-v3-design.md` - gym-flow, substitutions, summary, progress, and adherence design.
- `docs/superpowers/specs/2026-05-12-prep-ahead-lookahead-design.md` - Prep Ahead lookahead design.

Primary source material:

- `12_Week_Plan.docx` - original program source.
- `daily_companion.html` - earlier HTML companion/reference.
- `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift` - current typed in-app seed data.

## Current Stack / Runtime Truth

- Platform: iOS app.
- UI: SwiftUI.
- State observation: Swift Observation (`@Observable`, `@Environment(LocalAppState.self)`).
- Persistence: local `UserDefaults` JSON snapshot in `LocalAppState`; no accounts, no backend, no iCloud sync.
- Language: Swift 6.0.
- Deployment target: iOS 18.0.
- Tests: XCTest unit/source-guard tests in `WorkoutApp/WorkoutAppTests`.
- Project file: `WorkoutApp/WorkoutApp.xcodeproj` is the currently buildable Xcode project.
- Project generator spec: `WorkoutApp/project.yml` exists for XcodeGen, but do not regenerate the Xcode project casually. Preserve existing Xcode signing/project changes unless the task explicitly requires project regeneration.

Current app target settings verified from `xcodebuild -showBuildSettings`:

- Scheme: `WorkoutApp`
- App target: `WorkoutApp`
- Test target: `WorkoutAppTests`
- Bundle ID: `com.ansoncordeiro.WorkoutApp`
- Display name: `I'd Lift That`
- Development team: `FNZS4MVS45`
- Marketing version: `1.0`
- Current project version: `1`

## Source-Of-Truth Files

- `WorkoutApp/WorkoutApp/App/WorkoutApp.swift` - app entry point and root state injection.
- `WorkoutApp/WorkoutApp/App/RootTabView.swift` - tab structure, including Today, Progress, Food, Grocery, and Plan.
- `WorkoutApp/WorkoutApp/Models/ProgramModels.swift` - seed-program model types.
- `WorkoutApp/WorkoutApp/Models/UserLogModels.swift` - local user log model types.
- `WorkoutApp/WorkoutApp/ProgramData/ProgramSeed.swift` - canonical seeded workouts, meals, grocery ingredients, demos, and substitutions.
- `WorkoutApp/WorkoutApp/Store/LocalAppState.swift` - local persistence and app-state mutation API.
- `WorkoutApp/WorkoutApp/Core/WorkoutPlanner.swift` - workout lookup, active exercise, summary, and progression helpers.
- `WorkoutApp/WorkoutApp/Core/GroceryListGenerator.swift` - grocery-list generation.
- `WorkoutApp/WorkoutApp/Core/ProteinTracker.swift` - protein total helpers.
- `WorkoutApp/WorkoutApp/Features/**` - SwiftUI feature views.
- `WorkoutApp/WorkoutAppTests/**` - XCTest coverage and source guard tests.
- `.sessions/SESSION_INDEX.md` - newest-first session handoff index.

## Environment Variables

No required runtime environment variables are currently used by the app or tests. Source search found no `ProcessInfo`, API key, token, secret, or backend configuration usage.

Machine/tooling requirements:

- Xcode with iOS Simulator support.
- XcodeGen is installed on this machine (`xcodegen --version` reported `2.45.4`), but regeneration should be intentional because the checked-in `.xcodeproj` currently carries signing and Xcode-upgrade metadata.

## Commands

Run commands from repo root unless noted.

Inspect project:

```bash
xcodebuild -list -project WorkoutApp/WorkoutApp.xcodeproj
```

Run all tests on an available simulator:

```bash
xcodebuild test -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Build app without running tests:

```bash
xcodebuild build -project WorkoutApp/WorkoutApp.xcodeproj -scheme WorkoutApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Generate the Xcode project only when intentionally reconciling `WorkoutApp/project.yml`:

```bash
cd WorkoutApp
xcodegen generate
```

After any project regeneration, inspect `git diff` carefully before keeping the generated `.xcodeproj`.

## Deployment Notes

No deployment pipeline, App Store release workflow, Fastlane setup, or CI configuration is present in this repo. Treat this as a local Xcode project until release tooling is added.

## Working Rules For Future Agents

- Start every session by reading this file, then `.sessions/SESSION_INDEX.md`, then the latest session file listed there.
- Run `git status --short` before changing files. Preserve user changes and unrelated dirty files.
- Use the checked-in `.xcodeproj` for build/test truth unless the task specifically asks to update XcodeGen output.
- Do not run `xcodegen generate` as a routine cleanup step. If you must run it, document why and summarize the generated diff.
- Keep the app local-first unless a new product decision explicitly adds accounts, sync, backend services, or remote APIs.
- Prefer typed seed/model/core changes over hardcoding program data inside SwiftUI views.
- Add or update focused XCTest coverage for model, store, planner, grocery, and protein behavior when changing logic.
- For UI-only SwiftUI changes, at minimum run a simulator build. Run tests when practical.
- Do not delete source docs, plans, or config just because they look old. Delete only when current source truth proves they are false and safe to remove.
- No commits, pushes, production deploys, or external communications unless Anson explicitly asks.

## End-Of-Session Handoff Protocol

At the end of every substantive session:

1. Run `git status --short`.
2. Run the relevant verification command(s), or document exactly why they are blocked.
3. Add a dated session file under `.sessions/` named `YYYY-MM-DD__session-NN.md`.
4. Update `.sessions/SESSION_INDEX.md` with the newest session first.
5. In the session file, record:
   - goal and scope,
   - files changed,
   - decisions made,
   - verification run with exact commands and results,
   - known blockers or required env/services,
   - next recommended task.
6. Leave the repo in a state where the next agent can start by reading `AGENTS.md` and the latest session note without needing chat history.


<claude-mem-context>
# Memory Context

# [workout] recent context, 2026-05-24 11:41pm MDT

Legend: 🎯session 🔴bugfix 🟣feature 🔄refactor ✅change 🔵discovery ⚖️decision 🚨security_alert 🔐security_note
Format: ID TIME TYPE TITLE
Fetch details: get_observations([IDs]) | Search: mem-search skill

Stats: 7 obs (2,757t read) | 257,066t work | 99% savings

### May 24, 2026
297 9:32p 🔵 Workout project lacks session documentation and has pending Xcode changes
299 10:47p 🟣 Program switching with automatic grocery state cleanup
300 " 🔵 All 54 integration tests passing on iPhone 16e simulator
301 " ✅ Session documentation and planning committed to repository
302 10:49p ✅ Repository cleaned and optimized for handoff
303 10:52p ✅ Xcode project configuration upgraded and consolidated
304 11:19p ✅ Merged gym-performance-v2 feature branch into main with all tests passing

Access 257k tokens of past work via get_observations([IDs]) or mem-search skill.
</claude-mem-context>