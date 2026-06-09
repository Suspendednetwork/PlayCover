#!/bin/bash
set -e

echo "🚀 Roblox MacPlayer Installer for PlayCover"
echo ""

# Clean up
rm -rf /tmp/RobloxSetup 2>/dev/null || true
rm -f /tmp/roblox* 2>/dev/null || true

# Step 1: Get version from official API
echo "Fetching Roblox version..."
ROBLOX_VERSION=$(curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" | python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])")

if [ -z "$ROBLOX_VERSION" ]; then
    echo "❌ Failed to fetch version"
    exit 1
fi

echo "✓ Version: $ROBLOX_VERSION"

# Step 2: Try direct CDN URLs
echo ""
echo "Downloading from CDN..."

DOWNLOAD_OK=0
DL_FILE=""

# Try patterns
URLS=(
    "https://setup.rbxcdn.com/mac/${ROBLOX_VERSION}-RobloxPlayer.zip"
    "https://setup.rbxcdn.com/mac/Roblox.zip"
)

for URL in "${URLS[@]}"; do
    echo "Trying: $URL"
    
    if timeout 180 curl -L --fail --max-time 180 \
        -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        --progress-bar \
        -o /tmp/roblox_download.zip "$URL" 2>/dev/null; then
        
        # Check if it's actually a ZIP
        if file /tmp/roblox_download.zip | grep -q "Zip archive"; then
            SIZE=$(du -h /tmp/roblox_download.zip | cut -f1)
            echo "✓ Downloaded ($SIZE)"
            DOWNLOAD_OK=1
            DL_FILE="/tmp/roblox_download.zip"
            break
        else
            FILE_TYPE=$(file /tmp/roblox_download.zip | cut -d: -f2 | xargs)
            echo "✗ Invalid file type: $FILE_TYPE"
            rm -f /tmp/roblox_download.zip
        fi
    else
        echo "✗ Download failed"
        rm -f /tmp/roblox_download.zip
    fi
done

if [ "$DOWNLOAD_OK" -ne 1 ]; then
    echo ""
    echo "❌ Download failed"
    echo ""
    echo "The Roblox CDN may be temporarily unavailable."
    echo "Try again in a few moments."
    echo ""
    exit 1
fi

# Step 3: Extract
EXTRACT_DIR="/tmp/RobloxSetup"
mkdir -p "$EXTRACT_DIR"

echo ""
echo "Extracting..."
unzip -q "$DL_FILE" -d "$EXTRACT_DIR"

# Find .app
APP=$(find "$EXTRACT_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP" ]; then
    echo "❌ No .app bundle found"
    exit 1
fi

echo "✓ Found app: $(basename "$APP")"
echo ""

# Step 4: Modify
echo "Modifying app..."

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
    <string>Roblox-ROBLOX_VER</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Roblox needs access to your microphone.</string>
    <key>NSCameraUsageDescription</key>
    <string>Roblox needs access to your camera.</string>
</dict>
</plist>
PLIST

sed -i '' "s/ROBLOX_VER/${ROBLOX_VERSION}/" "$APP/Contents/Info.plist"

# Step 5: Code sign
echo "Code signing..."
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --deep --sign - --timestamp=none "$APP" 2>/dev/null || true

# Step 6: Install
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME="Roblox-${ROBLOX_VERSION}.app"
FINAL_PATH="$INSTALL_DIR/$APP_NAME"

[ -d "$FINAL_PATH" ] && rm -rf "$FINAL_PATH"

echo "Installing to $FINAL_PATH..."
mv "$APP" "$FINAL_PATH"

# Cleanup
rm -f "$DL_FILE"
rm -rf "$EXTRACT_DIR"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Installation complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Installed at: $FINAL_PATH"
echo ""
echo "To run:"
echo "  open \"$FINAL_PATH\""
echo ""
