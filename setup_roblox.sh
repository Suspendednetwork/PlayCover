#!/bin/bash
# Setup script for Roblox MacPlayer (for use with manually downloaded ZIP from RDD)

set -e

# Allow optional ZIP path argument
ZIP_PATH="${1}"

# If no argument, try to find ZIP in Downloads
if [ -z "$ZIP_PATH" ]; then
    echo "🔍 Looking for Roblox ZIP in ~/Downloads/..."
    
    # Find the most recent Roblox ZIP
    ZIP_PATH=$(find ~/Downloads -maxdepth 1 -name "Roblox*.zip" -o -name "*RobloxPlayer*.zip" 2>/dev/null | sort -r | head -1)
    
    if [ -z "$ZIP_PATH" ]; then
        echo "❌ No Roblox ZIP found in ~/Downloads/"
        echo ""
        echo "Please:"
        echo "  1. Download from: https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
        echo "  2. Then run: bash ~/setup_roblox.sh ~/Downloads/Roblox.zip"
        exit 1
    fi
fi

if [ ! -f "$ZIP_PATH" ]; then
    echo "❌ File not found: $ZIP_PATH"
    exit 1
fi

echo "🚀 Roblox MacPlayer Setup"
echo "ZIP: $ZIP_PATH"
echo ""

# Get version from clientsettings
echo "Fetching Roblox version..."
ROBLOX_VERSION=$(curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" | python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])")

if [ -z "$ROBLOX_VERSION" ]; then
    echo "⚠️ Could not fetch version, using generic name"
    ROBLOX_VERSION="$(date +%Y%m%d)"
fi

echo "✓ Version: $ROBLOX_VERSION"
echo ""

# Extract
EXTRACT_DIR="/tmp/RobloxSetup"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"

echo "Extracting ZIP..."
unzip -q "$ZIP_PATH" -d "$EXTRACT_DIR"

# Find .app
APP=$(find "$EXTRACT_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP" ]; then
    echo "❌ No .app bundle found in ZIP"
    echo "Contents:"
    find "$EXTRACT_DIR" -type f | head -20
    exit 1
fi

echo "✓ Found app: $(basename "$APP")"
echo ""

# Modify app
echo "Modifying app..."

MACOS_DIR="$APP/Contents/MacOS"

# Rename binaries
if [ -f "$MACOS_DIR/RobloxPlayer" ]; then
    mv "$MACOS_DIR/RobloxPlayer" "$MACOS_DIR/r"
    echo "  ✓ Renamed RobloxPlayer → r"
fi

if [ -f "$MACOS_DIR/RobloxPlayerInstaller" ]; then
    mv "$MACOS_DIR/RobloxPlayerInstaller" "$MACOS_DIR/r-installer"
    echo "  ✓ Renamed RobloxPlayerInstaller → r-installer"
fi

# Update Info.plist
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>r</string>
    <key>CFBundleIdentifier</key>
    <string>com.leonel.lovesyou</string>
    <key>CFBundleName</key>
    <string>Roblox</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>ROBLOX_VERSION_PLACEHOLDER</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Roblox needs access to your microphone.</string>
    <key>NSCameraUsageDescription</key>
    <string>Roblox needs access to your camera.</string>
</dict>
</plist>
PLIST

sed -i '' "s/ROBLOX_VERSION_PLACEHOLDER/Roblox-$ROBLOX_VERSION/" "$APP/Contents/Info.plist"

echo "  ✓ Updated Info.plist"
echo ""

# Code sign
echo "Code signing..."
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --deep --sign - --timestamp=none "$APP" 2>/dev/null || true
echo "  ✓ Signed"
echo ""

# Install
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME="Roblox-$ROBLOX_VERSION.app"
FINAL_PATH="$INSTALL_DIR/$APP_NAME"

if [ -d "$FINAL_PATH" ]; then
    echo "Removing old version..."
    rm -rf "$FINAL_PATH"
fi

echo "Installing to $FINAL_PATH..."
mv "$APP" "$FINAL_PATH"

# Cleanup
rm -rf "$EXTRACT_DIR"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Setup complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Installed at:"
echo "  $FINAL_PATH"
echo ""
echo "To run:"
echo "  open \"$FINAL_PATH\""
echo ""
echo "Or from Terminal:"
echo "  $FINAL_PATH/Contents/MacOS/r"
echo ""
