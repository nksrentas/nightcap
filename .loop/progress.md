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
