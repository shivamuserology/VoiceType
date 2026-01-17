#!/bin/bash

# VoiceType DMG Creation Script
# Usage: ./create-dmg.sh

set -e

APP_PATH="/Users/shivamsethi/Documents/VoiceType_1.1.1.app"
DMG_PATH="./VoiceType-1.1.1.dmg"
VOLUME_NAME="VoiceType"
VOLUME_ICON="./VoiceType/Resources/AppIcon.icns"

echo "💿 VoiceType DMG Creation Script"
echo "================================="

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: App not found at $APP_PATH"
    echo "Please build and notarize the app first"
    exit 1
fi

# Remove existing DMG
if [ -f "$DMG_PATH" ]; then
    echo "🗑  Removing existing DMG..."
    rm "$DMG_PATH"
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "📁 Creating temporary directory: $TEMP_DIR"

# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create symlink to Applications
ln -s /Applications "$TEMP_DIR/Applications"

# Create DMG
echo "💿 Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov -format UDZO \
    "$DMG_PATH"

# Cleanup
rm -rf "$TEMP_DIR"

# Notarize the DMG (optional but recommended)
echo ""
echo "📦 DMG created at: $DMG_PATH"
echo ""
echo "To notarize the DMG (recommended):"
echo "  xcrun notarytool submit '$DMG_PATH' --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --password @keychain:AC_PASSWORD --wait"
echo "  xcrun stapler staple '$DMG_PATH'"
echo ""
echo "✅ Done! Upload $DMG_PATH to your website for distribution."
