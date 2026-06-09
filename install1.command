#!/bin/bash
set -e

# --- CLEAN OLD RUN ARTIFACTS ---
rm -rf RobloxExtract 2>/dev/null || true
rm -f /tmp/roblox* 2>/dev/null || true

echo "Fetching latest Roblox version..."

ROBLOX_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "ERROR: Failed to fetch Roblox version."
    exit 1
fi

echo "Detected Roblox version: $ROBLOX_VERSION"

APP_VERSION="Roblox-$ROBLOX_VERSION"

# --- DOWNLOAD SOURCES (FALLBACK ORDER) ---
SOURCES=(
"https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
"https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer&arch=x86-64"
"https://rdd.weao.xyz/?channel=LIVE&binaryType=MacPlayer&includeLauncher=true&parallelDownloads=true"
)

# --- SAFE TEMP FILE (FIXED MKTEMP) ---
TMP_FILE=$(mktemp /tmp/roblox.XXXXXX)
ZIP_FILE="${TMP_FILE}.zip"
mv "$TMP_FILE" "$ZIP_FILE"

DOWNLOAD_OK=0

for URL in "${SOURCES[@]}"; do
    echo ""
    echo "Trying source:"
    echo "$URL"

    curl -L --fail --show-error \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36" \
        "$URL" -o "$ZIP_FILE"

    FILE_TYPE=$(file "$ZIP_FILE")
    echo "$FILE_TYPE"

    if echo "$FILE_TYPE" | grep -q "Zip archive data"; then
        echo "Valid ZIP downloaded."
        DOWNLOAD_OK=1
        break
    else
        echo "Invalid response (not ZIP). Trying next source..."
    fi
done

if [ "$DOWNLOAD_OK" -ne 1 ]; then
    echo "ERROR: All download sources failed."
    exit 1
fi

# --- EXTRACT ---
echo "Extracting..."
rm -rf RobloxExtract
mkdir -p RobloxExtract
unzip -q "$ZIP_FILE" -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Could not find Roblox app bundle."
    exit 1
fi

echo "Found: $APP"

# --- RENAME BINARIES ---
if [ -f "$APP/Contents/MacOS/RobloxPlayer" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayer" "$APP/Contents/MacOS/r"
fi

if [ -f "$APP/Contents/MacOS/RobloxPlayerInstaller" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayerInstaller" "$APP/Contents/MacOS/r-installer"
fi

# --- INFO PLIST ---
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

# --- CODE SIGNING ---
echo "Removing old signature..."
codesign --remove-signature "$APP" 2>/dev/null || true

echo "Re-signing app..."
codesign --force --deep --sign - "$APP"

echo "Verifying signature..."
codesign --verify --deep --strict "$APP"

# --- INSTALL ---
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

FINAL_PATH="$INSTALL_DIR/$APP_VERSION.app"

# remove old version if exists
rm -rf "$FINAL_PATH"

echo "Installing to $FINAL_PATH..."

mv "$APP" "$FINAL_PATH"

echo "Done."
echo "Installed at: $FINAL_PATH"
