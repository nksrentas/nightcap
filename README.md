# Nightcap ☕

A tiny macOS menu bar app that keeps your Mac awake, using the built-in `caffeinate` command, and tells you how much you use it.

Click the cup, tick **Keep Awake**, and your Mac won't sleep until you untick it or the timer runs out. The icon starts steaming while it's on.

```
✓ Keep Awake
  Duration                          ▸   Indefinitely · 15 Minutes · 30 Minutes · 1 Hour · 2 Hours · 4 Hours
  Awake since 21:19 · until 22:19
───────────────
STATISTICS
  12 sessions · 3 today
  4h 05m awake · longest 1h 20m
───────────────
  Reset Statistics
  Quit Nightcap                    ⌘Q
```

## Features

- **One-click toggle** from a native macOS menu. No Dock icon, no windows.
- **Timers**: stay awake indefinitely, or for 15 minutes up to 4 hours.
- **Stats**: sessions started, sessions today, total time kept awake, and your longest session. They're saved between launches and can be reset.
- **Can't leave caffeinate behind**: caffeinate runs with `-w <Nightcap's pid>`, so it exits with the app, even if the app crashes. Quitting while it's on still saves that session to the stats.
- **No dependencies**: Swift and SwiftUI only, and about 350 lines of app code.

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later (Swift 6 toolchain) to build it

## Install

There's no prebuilt download yet, so you build it yourself:

```bash
git clone https://github.com/nksrentas/nightcap.git
cd nightcap
bash scripts/bundle.sh
open build/Nightcap.app
```

To keep it, drag `build/Nightcap.app` into `/Applications`. To start it automatically, add it in **System Settings → General → Login Items**.

The app is ad-hoc signed, not notarized. Because you built it on your own Mac, Gatekeeper lets it run. If you copy it to another Mac, right-click it there and choose **Open** the first time.

## How it works

When you turn it on, Nightcap runs:

```bash
/usr/bin/caffeinate -d -i -m -s -w <nightcap-pid> [-t <seconds>]
```

| Flag | Prevents |
|---|---|
| `-d` | the display from sleeping |
| `-i` | the system from idle sleeping |
| `-m` | the disk from idle sleeping |
| `-s` | the system from sleeping on AC power |
| `-w` | caffeinate from outliving Nightcap |
| `-t` | (with a timer) anything past the chosen duration |

Turning it off stops that process. If caffeinate exits by itself (the timer ran out, or something killed it), Nightcap notices, turns itself off, and records the session.

Stats are stored in `UserDefaults` under `app.nightcap.Nightcap`.

## Development

```bash
swift build             # debug build
swift test              # 33 tests (Swift Testing)
swift run Nightcap      # run without bundling
bash scripts/bundle.sh  # release build to build/Nightcap.app
```

```
Sources/
  NightcapCore/     all logic, unit-tested
    CaffeinateController.swift  starts and stops caffeinate behind a small protocol
    StatsStore.swift            session stats, persisted to UserDefaults
    AppModel.swift              ties the two together (@Observable, @MainActor)
    DurationFormat.swift        "2h 05m"-style formatting
  Nightcap/         SwiftUI MenuBarExtra only
Tests/NightcapCoreTests/        fakes for the process and the clock, so tests never spawn caffeinate
scripts/bundle.sh               builds the .app, writes Info.plist, ad-hoc signs
```

Each test gets its own throwaway `UserDefaults` suite in the temp folder through the `.isolatedDefaults` trait, so test runs leave nothing in `~/Library/Preferences`.

### How it was built

Nightcap was built with an autonomous agent loop. `.loop/feature_list.json` lists each requirement along with the evidence that it passes, and `.loop/progress.md` logs every session.

## License

[MIT](LICENSE) © 2026 Nick Rentas
