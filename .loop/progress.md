# Brewtime — macOS menu bar caffeinate toggle with stats

Baseline (init): `swift build` ok, `swift test` 1 test passing (Swift Testing). Toolchain Swift 6.4, Xcode 27.1, macOS 26.

## Conventions
- Swift package, no Xcode project. `BrewtimeCore` (library, all logic, unit-tested) + `Brewtime` (executable, SwiftUI MenuBarExtra only) + `BrewtimeCoreTests` (Swift Testing: `import Testing`, `@Test`, `#expect`).
- The repo lives under a path with spaces ("Application Support"): quote every path in scripts.
- Keep UI thin; anything testable goes in BrewtimeCore with injected clock / process launcher / UserDefaults suite.
- Tests must not spawn real caffeinate; use the fake launcher.

## Assumptions
- App name: Brewtime. Minimum macOS 14 (for @Observable). caffeinate flags `-dims -w <pid>` so the display, idle and system sleep are blocked and caffeinate dies with the app.
- No launch-at-login, no notarization: ad-hoc signed local build.
- F1: durations are passed to `CaffeinateController.start(seconds:)` as whole seconds (`Int?`, nil = indefinitely).
- F2: a session counts as started (and toward "today") when it starts, not when it ends. `currentSessionStart` is in memory only, never persisted, so a crash cannot leave a stale running session. Durations truncate to whole seconds.

## Session 1 · F1 · 2026-10-23
Did: `Sources/BrewtimeCore/CaffeinateController.swift` — `@MainActor final class CaffeinateController` (`start(seconds:)`, `stop()`, `isActive`), protocols `ProcessLaunching` / `LaunchedProcess`, `SystemProcessLauncher` (Foundation `Process`, which conforms to `LaunchedProcess` by extension). 7 tests in `CaffeinateControllerTests.swift` with a `FakeLauncher`/`FakeProcess`.
Learned: `isActive` is just `process != nil`; nothing yet observes caffeinate exiting on its own — E1 will need a termination callback on `LaunchedProcess` (`Process.terminationHandler`, which fires off the main thread, so hop to MainActor). Swift Testing tests touching the controller need `@MainActor` on the `@Test` func. `.loop/verify.sh` prints `autoloop: verify passed` on success.
Next: F2

## Session 2 · F2 · 2026-10-23
Did: `Sources/BrewtimeCore/StatsStore.swift`, a `@MainActor final class StatsStore(defaults:now:calendar:)` with `startSession()` (count +1 right away, sets `currentSessionStart`), `endSession()` (adds the elapsed whole seconds to total and longest), `reset()`, and read-only `sessionsStarted`, `totalSeconds`, `longestSeconds`, `sessionsToday` and `currentSessionStart`. "Today" is stored as a start-of-day date plus a count, so storage stays bounded. Keys are `stats.*`. 8 tests in `StatsStoreTests.swift` (`TestClock`, a UUID defaults suite per test, a UTC calendar).
Learned: The PreToolUse commit guard checks before the Bash command runs, so `verify.sh && git commit` in one call is always blocked after a code edit: run the gate and the commit in separate calls. `UserDefaults.integer(forKey:)` already returns 0 for missing or non-numeric values, which E3 can lean on, but a numeric string like "12" still parses as 12. F3's AppModel should call `startSession()` on toggle on and `endSession()` on toggle off, and inject the same clock into both.
Next: F3

## Session 3 · F3 · 2026-10-23
Did: `Sources/BrewtimeCore/AppModel.swift` — `public enum SessionDuration: CaseIterable` (`indefinitely`, `minutes15`, `minutes30`, `hour1`, `hours2`, `hours4`; `seconds: Int?`) and `@Observable @MainActor final class AppModel(caffeinate:stats:)` with `selectedDuration`, stored `isActive`, `public let stats`, and `toggle() throws` (start caffeinate first, then `stats.startSession()`, so a failed launch counts nothing; off = stop + `endSession()`). 5 tests in `AppModelTests.swift`.
Learned: The clock is injected only into `StatsStore`; `CaffeinateController` needs none. `StatsStore` is not `@Observable`, so a SwiftUI view reading `model.stats.*` refreshes only when `AppModel` state changes (toggle) — F4's Reset Stats button will not redraw the stats on its own; F4 should either make `StatsStore` `@Observable` or route reset through the model. `SessionDuration` has no display labels yet; F4 owns them. E1 will need `AppModel` to observe caffeinate exiting (termination callback on `LaunchedProcess`) and flip the stored `isActive`.
Next: F5 (F7 and E3 are also unblocked)

## Session 4 · F4 · 2026-10-23
Did: Commit 07d6342. `Sources/Brewtime/BrewtimeApp.swift` — `MenuBarExtra` (`.window` style) owning `@State AppModel(CaffeinateController(), StatsStore(defaults: .standard))`, icon `cup.and.heat.waves.fill` when active, else `cup.and.saucer`. New `Sources/Brewtime/PanelView.swift`: "Keep Mac awake" switch (a launch error shows in red below), duration picker (labels in a private `SessionDuration.label` extension, disabled while active so remaining time stays right), live "Awake for" `Text(start, style: .timer)` plus "Remaining" `Text(timerInterval:countsDown:)` when a duration is set, stats rows, Reset Stats, Quit (⌘Q). `StatsStore` is now `@Observable`, so Reset Stats redraws the panel; test `resetNotifiesObserversOfTheStats`. Gate: 22 tests green, `swift build` ok. F4 stays false.
Learned: The sequential driver started F4 even though its dependency F7 is still false. Its verify needs `build/Brewtime.app` from F7's `scripts/bundle.sh`, which doesn't exist yet (`scripts/` is empty), and it needs a click on the menu bar toggle. This headless session has no GUI tool, and `.build/...` binaries and `osascript` are not on the allowlist. `pgrep -x caffeinate` is allowed. The panel formats durations with `Duration.formatted(.units(..., width: .narrow))` in `PanelView.formatted(_:)`; F5's helper should replace that function. No Dock icon depends on F7's `LSUIElement`: the panel code does not call `setActivationPolicy`. Inside `withObservationTracking`, `onChange` is `@Sendable`, so a test flag needs `OSAllocatedUnfairLock` (`import os`), not a captured `var`.
Next: F5, then F7. To unblock F4: after F7 passes, run `bash scripts/bundle.sh`, `open build/Brewtime.app`, toggle on from the menu bar, check `pgrep -lfx caffeinate` shows `-w <Brewtime pid>`, toggle off and check it's gone, then delete the Blocked line (or rerun F4 with a GUI tool in `LOOP_EXTRA_TOOLS`).
Blocked: F4
