#!/bin/bash
set -e

# --- CLEAN OLD RUN ARTIFACTS ---
rm -rf RobloxExtract 2>/dev/null || true
rm -f /tmp/roblox* 2>/dev/null || true

echo "Fetching latest Roblox version..."

# Get version info
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

# --- FETCH DEPLOYMENT MANIFEST ---
echo "Fetching deployment manifest..."

MANIFEST_URL="https://setup.rbxcdn.com/version-$ROBLOX_VERSION/version.txt"

# Fetch the version manifest to find the deployments
MANIFEST=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || echo "")

if [ -z "$MANIFEST" ]; then
    echo "ERROR: Could not fetch manifest from $MANIFEST_URL"
    exit 1
fi

# --- PARSE MAC DEPLOYMENT FROM MANIFEST ---
# Look for MacPlayer deployment in manifest
MAC_DEPLOYMENT=$(echo "$MANIFEST" | grep -i "mac" | grep -i "player" | head -n 1 || echo "")

if [ -z "$MAC_DEPLOYMENT" ]; then
    echo "ERROR: Could not find MacPlayer deployment in manifest."
    echo "Manifest content (first 500 chars):"
    echo "$MANIFEST" | head -c 500
    exit 1
fi

# --- CONSTRUCT DIRECT CDN URL ---
# Format: https://setup.rbxcdn.com/mac/RobloxPlayer.zip
CDN_URL="https://setup.rbxcdn.com/mac/RobloxPlayer.zip"

echo "Using CDN URL: $CDN_URL"

# --- SAFE TEMP FILE ---
TMP_FILE=$(mktemp /tmp/roblox.XXXXXX)
ZIP_FILE="${TMP_FILE}.zip"
mv "$TMP_FILE" "$ZIP_FILE"

# --- DOWNLOAD WITH RETRY ---
echo "Downloading Roblox MacPlayer..."

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES"
    
    if curl -L --fail --show-error --max-time 120 \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$CDN_URL" -o "$ZIP_FILE"; then
        
        FILE_TYPE=$(file "$ZIP_FILE")
        echo "Downloaded file type: $FILE_TYPE"
        
        if echo "$FILE_TYPE" | grep -q "Zip archive data"; then
            echo "✓ Valid ZIP downloaded."
            break
        else
            echo "✗ Invalid response (not ZIP). Retrying..."
            rm -f "$ZIP_FILE"
            RETRY_COUNT=$((RETRY_COUNT + 1))
        fi
    else
        echo "✗ Download failed. Retrying..."
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ ! -f "$ZIP_FILE" ] || ! file "$ZIP_FILE" | grep -q "Zip archive data"; then
    echo "ERROR: Failed to download valid Roblox ZIP after $MAX_RETRIES attempts."
    exit 1
fi

# --- EXTRACT ---
echo "Extracting..."
rm -rf RobloxExtract
mkdir -p RobloxExtract
unzip -q "$ZIP_FILE" -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "ERROR: Could not find Roblox app bundle in ZIP."
    echo "Contents of RobloxExtract:"
    find RobloxExtract -type f | head -20
    exit 1
fi

echo "Found app: $APP"

# --- RENAME BINARIES ---
if [ -f "$APP/Contents/MacOS/RobloxPlayer" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayer" "$APP/Contents/MacOS/r"
    echo "Renamed RobloxPlayer → r"
fi

if [ -f "$APP/Contents/MacOS/RobloxPlayerInstaller" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayerInstaller" "$APP/Contents/MacOS/r-installer"
    echo "Renamed RobloxPlayerInstaller → r-installer"
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
codesign --force --deep --sign - --timestamp=none "$APP"

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

# --- CLEANUP ---
rm -f "$ZIP_FILE"
rm -rf RobloxExtract

echo ""
echo "✓ Done."
echo "✓ Installed at: $FINAL_PATH"
echo ""
echo "To run:"
echo "open \"$FINAL_PATH\""#!/bin/bash
set -e

# --- CLEAN OLD RUN ARTIFACTS ---
rm -rf RobloxExtract 2>/dev/null || true
rm -f /tmp/roblox* 2>/dev/null || true

echo "Fetching latest Roblox version..."

# Get version info
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

# --- FETCH DEPLOYMENT MANIFEST ---
echo "Fetching deployment manifest..."

MANIFEST_URL="https://setup.rbxcdn.com/version-$ROBLOX_VERSION/version.txt"

# Fetch the version manifest to find the deployments
MANIFEST=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || echo "")

if [ -z "$MANIFEST" ]; then
    echo "ERROR: Could not fetch manifest from $MANIFEST_URL"
    exit 1
fi

# --- PARSE MAC DEPLOYMENT FROM MANIFEST ---
# Look for MacPlayer deployment in manifest
MAC_DEPLOYMENT=$(echo "$MANIFEST" | grep -i "mac" | grep -i "player" | head -n 1 || echo "")

if [ -z "$MAC_DEPLOYMENT" ]; then
    echo "ERROR: Could not find MacPlayer deployment in manifest."
    echo "Manifest content (first 500 chars):"
    echo "$MANIFEST" | head -c 500
    exit 1
fi

# --- CONSTRUCT DIRECT CDN URL ---
# Format: https://setup.rbxcdn.com/mac/RobloxPlayer.zip
CDN_URL="https://setup.rbxcdn.com/mac/RobloxPlayer.zip"

echo "Using CDN URL: $CDN_URL"

# --- SAFE TEMP FILE ---
TMP_FILE=$(mktemp /tmp/roblox.XXXXXX)
ZIP_FILE="${TMP_FILE}.zip"
mv "$TMP_FILE" "$ZIP_FILE"

# --- DOWNLOAD WITH RETRY ---
echo "Downloading Roblox MacPlayer..."

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES"
    
    if curl -L --fail --show-error --max-time 120 \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$CDN_URL" -o "$ZIP_FILE"; then
        
        FILE_TYPE=$(file "$ZIP_FILE")
        echo "Downloaded file type: $FILE_TYPE"
        
        if echo "$FILE_TYPE" | grep -q "Zip archive data"; then
            echo "✓ Valid ZIP downloaded."
            break
        else
            echo "✗ Invalid response (not ZIP). Retrying..."
            rm -f "$ZIP_FILE"
            RETRY_COUNT=$((RETRY_COUNT + 1))
        fi
    else
        echo "✗ Download failed. Retrying..."
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ ! -f "$ZIP_FILE" ] || ! file "$ZIP_FILE" | grep -q "Zip archive data"; then
    echo "ERROR: Failed to download valid Roblox ZIP after $MAX_RETRIES attempts."
    exit 1
fi

# --- EXTRACT ---
echo "Extracting..."
rm -rf RobloxExtract
mkdir -p RobloxExtract
unzip -q "$ZIP_FILE" -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "ERROR: Could not find Roblox app bundle in ZIP."
    echo "Contents of RobloxExtract:"
    find RobloxExtract -type f | head -20
    exit 1
fi

echo "Found app: $APP"

# --- RENAME BINARIES ---
if [ -f "$APP/Contents/MacOS/RobloxPlayer" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayer" "$APP/Contents/MacOS/r"
    echo "Renamed RobloxPlayer → r"
fi

if [ -f "$APP/Contents/MacOS/RobloxPlayerInstaller" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayerInstaller" "$APP/Contents/MacOS/r-installer"
    echo "Renamed RobloxPlayerInstaller → r-installer"
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
codesign --force --deep --sign - --timestamp=none "$APP"

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

# --- CLEANUP ---
rm -f "$ZIP_FILE"
rm -rf RobloxExtract

echo ""
echo "✓ Done."
echo "✓ Installed at: $FINAL_PATH"
echo ""
echo "To run:"
echo "open \"$FINAL_PATH\""#!/bin/bash
set -e

# --- CLEAN OLD RUN ARTIFACTS ---
rm -rf RobloxExtract 2>/dev/null || true
rm -f /tmp/roblox* 2>/dev/null || true

echo "Fetching latest Roblox version..."

# Get version info
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

# --- FETCH DEPLOYMENT MANIFEST ---
echo "Fetching deployment manifest..."

MANIFEST_URL="https://setup.rbxcdn.com/version-$ROBLOX_VERSION/version.txt"

# Fetch the version manifest to find the deployments
MANIFEST=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || echo "")

if [ -z "$MANIFEST" ]; then
    echo "ERROR: Could not fetch manifest from $MANIFEST_URL"
    exit 1
fi

# --- PARSE MAC DEPLOYMENT FROM MANIFEST ---
# Look for MacPlayer deployment in manifest
MAC_DEPLOYMENT=$(echo "$MANIFEST" | grep -i "mac" | grep -i "player" | head -n 1 || echo "")

if [ -z "$MAC_DEPLOYMENT" ]; then
    echo "ERROR: Could not find MacPlayer deployment in manifest."
    echo "Manifest content (first 500 chars):"
    echo "$MANIFEST" | head -c 500
    exit 1
fi

# --- CONSTRUCT DIRECT CDN URL ---
# Format: https://setup.rbxcdn.com/mac/RobloxPlayer.zip
CDN_URL="https://setup.rbxcdn.com/mac/RobloxPlayer.zip"

echo "Using CDN URL: $CDN_URL"

# --- SAFE TEMP FILE ---
TMP_FILE=$(mktemp /tmp/roblox.XXXXXX)
ZIP_FILE="${TMP_FILE}.zip"
mv "$TMP_FILE" "$ZIP_FILE"

# --- DOWNLOAD WITH RETRY ---
echo "Downloading Roblox MacPlayer..."

MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES"
    
    if curl -L --fail --show-error --max-time 120 \
        -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
        "$CDN_URL" -o "$ZIP_FILE"; then
        
        FILE_TYPE=$(file "$ZIP_FILE")
        echo "Downloaded file type: $FILE_TYPE"
        
        if echo "$FILE_TYPE" | grep -q "Zip archive data"; then
            echo "✓ Valid ZIP downloaded."
            break
        else
            echo "✗ Invalid response (not ZIP). Retrying..."
            rm -f "$ZIP_FILE"
            RETRY_COUNT=$((RETRY_COUNT + 1))
        fi
    else
        echo "✗ Download failed. Retrying..."
        RETRY_COUNT=$((RETRY_COUNT + 1))
    fi
done

if [ ! -f "$ZIP_FILE" ] || ! file "$ZIP_FILE" | grep -q "Zip archive data"; then
    echo "ERROR: Failed to download valid Roblox ZIP after $MAX_RETRIES attempts."
    exit 1
fi

# --- EXTRACT ---
echo "Extracting..."
rm -rf RobloxExtract
mkdir -p RobloxExtract
unzip -q "$ZIP_FILE" -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "ERROR: Could not find Roblox app bundle in ZIP."
    echo "Contents of RobloxExtract:"
    find RobloxExtract -type f | head -20
    exit 1
fi

echo "Found app: $APP"

# --- RENAME BINARIES ---
if [ -f "$APP/Contents/MacOS/RobloxPlayer" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayer" "$APP/Contents/MacOS/r"
    echo "Renamed RobloxPlayer → r"
fi

if [ -f "$APP/Contents/MacOS/RobloxPlayerInstaller" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayerInstaller" "$APP/Contents/MacOS/r-installer"
    echo "Renamed RobloxPlayerInstaller → r-installer"
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
codesign --force --deep --sign - --timestamp=none "$APP"

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

# --- CLEANUP ---
rm -f "$ZIP_FILE"
rm -rf RobloxExtract

echo ""
echo "✓ Done."
echo "✓ Installed at: $FINAL_PATH"
echo ""
echo "To run:"
echo "open \"$FINAL_PATH\""
