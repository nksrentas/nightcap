#!/usr/bin/env bash
# Builds a release binary and assembles an ad-hoc signed build/Brewtime.app.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --product Brewtime
bin="$(swift build -c release --show-bin-path)/Brewtime"
version="$(sed -n 's/.*version = "\(.*\)".*/\1/p' "Sources/BrewtimeCore/Version.swift")"

app="build/Brewtime.app"
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$bin" "$app/Contents/MacOS/Brewtime"

cat > "$app/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Brewtime</string>
    <key>CFBundleIdentifier</key>
    <string>app.brewtime.Brewtime</string>
    <key>CFBundleName</key>
    <string>Brewtime</string>
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
