# Coding standards

1. Logic lives in `Sources/BrewtimeCore`; `Sources/Brewtime` contains only SwiftUI views and app wiring.
2. Inject side effects (process launching, clock, UserDefaults) through initializers; no singletons besides the app entry point.
3. Tests use Swift Testing (`@Test`, `#expect`), one file per type under `Tests/BrewtimeCoreTests`, and never spawn real processes.
4. Swift 6 strict concurrency: UI-facing state is `@MainActor`; no `@unchecked Sendable` without a comment saying why.
5. Names follow Swift API Design Guidelines; no abbreviations beyond common ones (UI, ID).
6. No force unwraps or `try!` outside tests.
7. Scripts are bash with `set -euo pipefail` and quote every path.

## bussin-lean
- No speculative abstractions, options or dependencies; no third-party packages.
- No dead code, unused declarations, commented-out code or debug prints left in the diff.
