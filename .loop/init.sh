#!/usr/bin/env bash
# No dev server: Brewtime is a native menu bar app. Build so the session starts from a compiling tree.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
[ "${1:-}" = stop ] && exit 0
swift build 2>&1 | tail -n 3
echo "Run the app with: swift run Brewtime   (or bash scripts/bundle.sh, then open build/Brewtime.app)"
