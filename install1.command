#!/bin/bash
set -e

echo "🚀 Roblox MacPlayer Installer for PlayCover"
echo ""

# Clean up
rm -rf /tmp/RobloxExtract 2>/dev/null || true
rm -f /tmp/roblox*.dmg /tmp/roblox*.zip 2>/dev/null || true

# Step 1: Get version
echo "Fetching latest Roblox version..."
ROBLOX_VERSION=$(curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" | python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])")

if [ -z "$ROBLOX_VERSION" ]; then
    echo "❌ Failed to fetch version"
    exit 1
fi

echo "✓ Version: $ROBLOX_VERSION"

# Step 2: Download DMG
echo "Downloading Roblox MacPlayer from CDN..."

DMG_FILE=""

# Try to download from direct CDN URL
if curl -L --fail --max-time 300 -o /tmp/roblox.dmg \
    "https://setup.rbxcdn.com/mac/Roblox.dmg" 2>/dev/null && \
    [ -s /tmp/roblox.dmg ]; then
    
    if file /tmp/roblox.dmg | grep -q "Apple"; then
        echo "✓ Downloaded DMG successfully"
        DMG_FILE="/tmp/roblox.dmg"
    fi
fi

# If DMG failed, the file might be HTML (403 error page)
if [ -z "$DMG_FILE" ] && [ -f /tmp/roblox.dmg ]; then
    echo "⚠️ Download returned non-DMG file, checking content..."
    HEAD=$(head -c 100 /tmp/roblox.dmg)
    if echo "$HEAD" | grep -q "html\|<!DOCTYPE"; then
        echo "Got HTML response (403 or redirect). Download is blocked."
    fi
    rm -f /tmp/roblox.dmg
fi

# If direct CDN didn't work, nothing will - RDD is browser-only
if [ -z "$DMG_FILE" ]; then
    echo ""
    echo "❌ Download failed. The Roblox CDN requires browser access."
    echo ""
    echo "MANUAL FIX: Use RDD (browser) to download:"
    echo "  1. Visit: https://rdd.latte.to/"
    echo "  2. Set binaryType to 'MacPlayer'"
    echo "  3. Click Download"
    echo "  4. Extract the ZIP to ~/Applications/Roblox-version.app"
    echo ""
    echo "Or download official Roblox from: https://www.roblox.com/download"
    exit 1
fi

# Step 3: Mount DMG and extract
echo "Mounting DMG..."
MOUNT_POINT=$(/usr/bin/mktemp -d)
hdiutil attach "$DMG_FILE" -mountpoint "$MOUNT_POINT" -nobrowse >/dev/null 2>&1

EXTRACT_DIR="/tmp/RobloxExtract"
mkdir -p "$EXTRACT_DIR"

# Find and copy the .app
APP_FOUND=$(find "$MOUNT_POINT" -maxdepth 2 -name "*.app" -type d | head -1)

if [ -z "$APP_FOUND" ]; then
    echo "❌ No .app bundle found in DMG"
    hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
    exit 1
fi

echo "✓ Found app: $(basename "$APP_FOUND")"
cp -r "$APP_FOUND" "$EXTRACT_DIR/"

hdiutil detach "$MOUNT_POINT" 2>/dev/null || true
rm -rf "$MOUNT_POINT"

# Step 4: Modify app
APP="$EXTRACT_DIR/$(basename "$APP_FOUND")"

echo "Modifying app bundle..."

MACOS_DIR="$APP/Contents/MacOS"

if [ -f "$MACOS_DIR/RobloxPlayer" ]; then
    mv "$MACOS_DIR/RobloxPlayer" "$MACOS_DIR/r"
fi

if [ -f "$MACOS_DIR/RobloxPlayerInstaller" ]; then
    mv "$MACOS_DIR/RobloxPlayerInstaller" "$MACOS_DIR/r-installer"
fi

# Update plist
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
    <string>ROBLOX_VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Roblox needs access to your microphone.</string>
    <key>NSCameraUsageDescription</key>
    <string>Roblox needs access to your camera.</string>
</dict>
</plist>
PLIST

sed -i '' "s/ROBLOX_VERSION/Roblox-$ROBLOX_VERSION/" "$APP/Contents/Info.plist"

# Step 5: Code sign
echo "Code signing..."
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --deep --sign - --timestamp=none "$APP" 2>/dev/null || true

# Step 6: Install
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME="Roblox-$ROBLOX_VERSION.app"
FINAL_PATH="$INSTALL_DIR/$APP_NAME"

[ -d "$FINAL_PATH" ] && rm -rf "$FINAL_PATH"

echo "Installing to $FINAL_PATH..."
mv "$APP" "$FINAL_PATH"

rm -f "$DMG_FILE"
rm -rf "$EXTRACT_DIR"

echo ""
echo "============================================================"
echo "✅ Installation complete!"
echo "============================================================"
echo "Installed at: $FINAL_PATH"
echo ""
echo "To run: open \"$FINAL_PATH\""
echo ""
