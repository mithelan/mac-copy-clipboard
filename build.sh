#!/bin/bash
# Builds ClipboardHistory.app directly with swiftc (bypasses `swift build`,
# whose Package.swift manifest fails to link on some Command Line Tools-only
# installs). No Xcode.app is required.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="ClipboardHistory"
APP_DIR="$APP_NAME.app"
SRC_DIR="Sources/ClipboardHistory"

echo "Compiling $APP_NAME..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

swiftc "$SRC_DIR"/*.swift \
    -o "$APP_DIR/Contents/MacOS/$APP_NAME" \
    -O \
    -framework AppKit \
    -framework Carbon \
    -framework SwiftUI \
    -framework Combine

cp Info.plist "$APP_DIR/Contents/Info.plist"

echo "Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

echo ""
echo "Built $APP_DIR"
echo "Move it to /Applications, then double-click to launch (or right-click > Open the first time if Gatekeeper warns about an unidentified developer)."
