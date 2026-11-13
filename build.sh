#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CalendarBar"
APP_BUNDLE="$DIR/$APP_NAME.app"
MACOS_DIR="$APP_BUNDLE/Contents/MacOS"

echo "🔨 Building $APP_NAME..."

mkdir -p "$MACOS_DIR"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
if [ -f "$DIR/Resources/AppIcon.icns" ]; then
    cp "$DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

swiftc -O "$DIR/CalendarBar.swift" -o "$MACOS_DIR/$APP_NAME"

chmod +x "$MACOS_DIR/$APP_NAME"

echo "✅ Successfully built $APP_BUNDLE"
echo "👉 To launch, run: open '$APP_BUNDLE'"
