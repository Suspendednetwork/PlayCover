#!/bin/bash
set -e

# Roblox MacPlayer Installer for PlayCover
# Updated to use .dmg files from official Roblox CDN

echo "🚀 Roblox MacPlayer Installer for PlayCover"
echo ""

# Clean up old artifacts
rm -rf /tmp/RobloxExtract 2>/dev/null || true
rm -f /tmp/roblox*.dmg 2>/dev/null || true

# Step 1: Fetch version
echo "Fetching latest Roblox version..."
ROBLOX_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])" 2>/dev/null
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "❌ Failed to fetch Roblox version"
    exit 1
fi

echo "✓ Version: $ROBLOX_VERSION"

# Step 2: Download DMG
echo "Downloading Roblox MacPlayer..."

# Try different CDN URLs for the DMG
DMG_URLS=(
    "https://setup.rbxcdn.com/mac/Roblox.dmg"
    "https://setup.rbxcdn.com/mac/arm64/Roblox.dmg"
    "https://s3-us-west-2.amazonaws.com/setup-rbxcdn.com/mac/Roblox.dmg"
)

DMG_FILE=""
for URL in "${DMG_URLS[@]}"; do
    echo "Trying: $URL"
    
    if curl -L --fail --show-error --max-time 180 \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$URL" -o "/tmp/roblox_temp.dmg" 2>/dev/null; then
        
        # Check if it's actually a DMG
        if file /tmp/roblox_temp.dmg | grep -q "VAX COFF"; then
            echo "✓ Valid DMG downloaded"
            DMG_FILE="/tmp/roblox_temp.dmg"
            break
        else
            FILE_TYPE=$(file /tmp/roblox_temp.dmg | cut -d: -f2)
            echo "⚠️ Invalid file type:$FILE_TYPE"
            rm -f /tmp/roblox_temp.dmg
        fi
    else
        echo "✗ Download failed"
        rm -f /tmp/roblox_temp.dmg
    fi
done

if [ -z "$DMG_FILE" ]; then
    echo "❌ All CDN URLs failed. Trying fallback method..."
    
    # Fallback: Use curl with verbose to debug
    echo "Debug: Attempting RDD endpoint directly..."
    curl -v -L "https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer" \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        -o "/tmp/roblox_temp.dmg" 2>&1 | head -20
    
    if [ -f "/tmp/roblox_temp.dmg" ] && [ -s "/tmp/roblox_temp.dmg" ]; then
        FILE_TYPE=$(file /tmp/roblox_temp.dmg)
        echo "Downloaded file type: $FILE_TYPE"
        
        # Check for ZIP format
        if file /tmp/roblox_temp.dmg | grep -q "Zip archive"; then
            mv /tmp/roblox_temp.dmg /tmp/roblox_temp.zip
            DMG_FILE="/tmp/roblox_temp.zip"
        else
            DMG_FILE="/tmp/roblox_temp.dmg"
        fi
    else
        echo "❌ Fallback method failed"
        exit 1
    fi
fi

# Step 3: Mount or extract DMG
echo "Extracting Roblox app bundle..."

EXTRACT_DIR="/tmp/RobloxExtract"
mkdir -p "$EXTRACT_DIR"

if file "$DMG_FILE" | grep -q "Zip archive"; then
    # It's a ZIP file
    echo "Extracting ZIP..."
    unzip -q "$DMG_FILE" -d "$EXTRACT_DIR"
else
    # It's a DMG, mount it
    echo "Mounting DMG..."
    MOUNT_POINT=$(/usr/bin/mktemp -d)
    hdiutil attach "$DMG_FILE" -mountpoint "$MOUNT_POINT" -nobrowse >/dev/null 2>&1
    
    # Copy the .app bundle
    if [ -d "$MOUNT_POINT/Roblox.app" ]; then
        cp -r "$MOUNT_POINT/Roblox.app" "$EXTRACT_DIR/"
    elif [ -d "$MOUNT_POINT/RobloxPlayer.app" ]; then
        cp -r "$MOUNT_POINT/RobloxPlayer.app" "$EXTRACT_DIR/"
    else
        echo "Looking for .app in:"
        find "$MOUNT_POINT" -name "*.app" -type d | head -5
        
        APP_FOUND=$(find "$MOUNT_POINT" -maxdepth 2 -name "*.app" -type d | head -1)
        if [ -n "$APP_FOUND" ]; then
            cp -r "$APP_FOUND" "$EXTRACT_DIR/"
        fi
    fi
    
    # Unmount
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
    rm -rf "$MOUNT_POINT"
fi

# Find the .app
APP=$(find "$EXTRACT_DIR" -name "*.app" -type d | head -1)

if [ -z "$APP" ]; then
    echo "❌ Could not find .app bundle"
    echo "Contents of extract directory:"
    find "$EXTRACT_DIR" | head -20
    exit 1
fi

echo "✓ Found app: $(basename "$APP")"

# Step 4: Modify the app
echo "Modifying app bundle..."

MACOS_DIR="$APP/Contents/MacOS"

# Rename binaries if they exist
if [ -f "$MACOS_DIR/RobloxPlayer" ]; then
    mv "$MACOS_DIR/RobloxPlayer" "$MACOS_DIR/r"
    echo "  Renamed RobloxPlayer → r"
fi

if [ -f "$MACOS_DIR/RobloxPlayerInstaller" ]; then
    mv "$MACOS_DIR/RobloxPlayerInstaller" "$MACOS_DIR/r-installer"
    echo "  Renamed RobloxPlayerInstaller → r-installer"
fi

# Create new Info.plist
cat > "$APP/Contents/Info.plist" <<'EOF'
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
    <string>Roblox needs access to your microphone to chat with voice.</string>
    <key>NSCameraUsageDescription</key>
    <string>Roblox needs access to your camera for beta features.</string>
</dict>
</plist>
EOF

sed -i '' "s/ROBLOX_VERSION/Roblox-$ROBLOX_VERSION/" "$APP/Contents/Info.plist"

# Step 5: Code sign
echo "Code signing app..."
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --deep --sign - --timestamp=none "$APP" 2>&1 | grep -v "^Warning" || true

# Step 6: Install
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME="Roblox-$ROBLOX_VERSION.app"
FINAL_PATH="$INSTALL_DIR/$APP_NAME"

if [ -d "$FINAL_PATH" ]; then
    rm -rf "$FINAL_PATH"
fi

echo "Installing to $FINAL_PATH..."
mv "$APP" "$FINAL_PATH"

# Cleanup
rm -f "$DMG_FILE"
rm -rf "$EXTRACT_DIR"

echo ""
echo "============================================================"
echo "✅ Installation complete!"
echo "============================================================"
echo "Installed at: $FINAL_PATH"
echo ""
echo "To run:"
echo "  open \"$FINAL_PATH\""
echo ""
