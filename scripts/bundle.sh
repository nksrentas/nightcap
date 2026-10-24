#!/usr/bin/env bash
# Builds a release binary and assembles an ad-hoc signed build/Nightcap.app.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product Nightcap
bin="$(swift build -c release --show-bin-path)/Nightcap"
version="$(sed -n 's/.*version = "\(.*\)".*/\1/p' "Sources/NightcapCore/Version.swift")"

app="build/Nightcap.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/Nightcap"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Nightcap</string>
    <key>CFBundleIdentifier</key>
    <string>app.nightcap.Nightcap</string>
    <key>CFBundleName</key>
    <string>Nightcap</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$app"
echo "Built $app"
