#!/bin/bash
set -e

echo "🚀 Roblox Installer for macOS"
echo ""

# --- STEP 1: GET VERSION ---
echo "Fetching latest Roblox version..."

ROBLOX_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])" 2>&1
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "❌ Failed to fetch version"
    exit 1
fi

echo "✓ Version: $ROBLOX_VERSION"

APP_VERSION="Roblox-$ROBLOX_VERSION"

# --- STEP 2: DOWNLOAD ---
# Use RDD's direct approach: construct a browser-downloadable link
# Then use curl with proper headers to trigger the download

TMP_FILE=$(mktemp /tmp/roblox.XXXXXX)
ZIP_FILE="${TMP_FILE}.zip"
mv "$TMP_FILE" "$ZIP_FILE"

echo "Downloading Roblox MacPlayer..."

# Method 1: Direct S3 CDN URL
CDN_URL="https://setup.rbxcdn.com/mac/RobloxPlayer.zip"

if ! curl -L --fail --show-error --max-time 180 \
    -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    "$CDN_URL" -o "$ZIP_FILE" 2>&1; then
    echo "❌ Download failed"
    rm -f "$ZIP_FILE"
    exit 1
fi

# Verify it's a ZIP
if ! file "$ZIP_FILE" | grep -q "Zip archive data"; then
    echo "❌ Downloaded file is not a valid ZIP"
    echo "File type: $(file "$ZIP_FILE")"
    echo "First 200 bytes:"
    head -c 200 "$ZIP_FILE" | od -c | head -10
    rm -f "$ZIP_FILE"
    exit 1
fi

echo "✓ Valid ZIP downloaded"

# --- STEP 3: EXTRACT ---
echo "Extracting..."
rm -rf RobloxExtract
mkdir -p RobloxExtract
unzip -q "$ZIP_FILE" -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" -type d | head -n 1)

if [ -z "$APP" ]; then
    echo "❌ Could not find .app bundle"
    echo "Contents:"
    find RobloxExtract -type f | head -20
    exit 1
fi

echo "✓ Found: $APP"

# --- STEP 4: MODIFY & SIGN ---
echo "Modifying app bundle..."

if [ -f "$APP/Contents/MacOS/RobloxPlayer" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayer" "$APP/Contents/MacOS/r"
fi

if [ -f "$APP/Contents/MacOS/RobloxPlayerInstaller" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayerInstaller" "$APP/Contents/MacOS/r-installer"
fi

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
	<string>VERSION_PLACEHOLDER</string>
	<key>LSMinimumSystemVersion</key>
	<string>10.13</string>
	<key>NSMicrophoneUsageDescription</key>
	<string>Roblox needs access to your microphone to chat with voice.</string>
	<key>NSCameraUsageDescription</key>
	<string>Roblox needs access to your camera for beta features.</string>
</dict>
</plist>
EOF

sed -i '' "s/VERSION_PLACEHOLDER/$APP_VERSION/" "$APP/Contents/Info.plist"

echo "Code signing..."
codesign --remove-signature "$APP" 2>/dev/null || true
codesign --force --deep --sign - --timestamp=none "$APP"
codesign --verify --deep --strict "$APP" || true

# --- STEP 5: INSTALL ---
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"
FINAL_PATH="$INSTALL_DIR/$APP_VERSION.app"
rm -rf "$FINAL_PATH"

echo "Installing to $FINAL_PATH..."
mv "$APP" "$FINAL_PATH"

# Cleanup
rm -f "$ZIP_FILE"
rm -rf RobloxExtract

echo ""
echo "✅ Done! Installed at:"
echo "   $FINAL_PATH"
echo ""
echo "To run: open \"$FINAL_PATH\""
