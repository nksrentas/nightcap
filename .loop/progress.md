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

## Session 1 · F1 · 2026-10-23
Did: `Sources/BrewtimeCore/CaffeinateController.swift` — `@MainActor final class CaffeinateController` (`start(seconds:)`, `stop()`, `isActive`), protocols `ProcessLaunching` / `LaunchedProcess`, `SystemProcessLauncher` (Foundation `Process`, which conforms to `LaunchedProcess` by extension). 7 tests in `CaffeinateControllerTests.swift` with a `FakeLauncher`/`FakeProcess`.
Learned: `isActive` is just `process != nil`; nothing yet observes caffeinate exiting on its own — E1 will need a termination callback on `LaunchedProcess` (`Process.terminationHandler`, which fires off the main thread, so hop to MainActor). Swift Testing tests touching the controller need `@MainActor` on the `@Test` func. `.loop/verify.sh` prints `autoloop: verify passed` on success.
Next: F2
