#!/bin/bash
set -e

echo "Select Roblox download source:"
echo "1) rdd.latte.to (default)"
echo "2) rdd.latte.to (x86-64)"
echo "3) rdd.weao.xyz (alternative)"
read -rp "Enter choice (1-3): " CHOICE

if [ "$CHOICE" = "1" ]; then
    DOWNLOAD_URL="https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
elif [ "$CHOICE" = "2" ]; then
    DOWNLOAD_URL="https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer&arch=x86-64"
elif [ "$CHOICE" = "3" ]; then
    DOWNLOAD_URL="https://rdd.weao.xyz/?channel=LIVE&binaryType=MacPlayer&includeLauncher=true&parallelDownloads=true"
else
    echo "Invalid choice. Exiting."
    exit 1
fi

echo "Downloading Roblox..."

ZIP_FILE=$(mktemp /tmp/roblox.XXXXXX.zip)

curl -L --fail --show-error "$DOWNLOAD_URL" -o "$ZIP_FILE"

echo "Checking file type..."

FILE_TYPE=$(file "$ZIP_FILE")
echo "$FILE_TYPE"

if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP file."
    exit 1
fi

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

# --- VERSION DETECTION ---
VERSION_HASH=$(basename "$ZIP_FILE" | grep -oE '[a-f0-9]{6,}' || echo "unknown")
APP_VERSION="Roblox-$VERSION_HASH"

echo "Detected version: $APP_VERSION"

# Rename binaries safely
if [ -f "$APP/Contents/MacOS/RobloxPlayer" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayer" "$APP/Contents/MacOS/r"
fi

if [ -f "$APP/Contents/MacOS/RobloxPlayerInstaller" ]; then
    mv "$APP/Contents/MacOS/RobloxPlayerInstaller" "$APP/Contents/MacOS/r-installer"
fi

# Replace Info.plist
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

# inject version into plist
sed -i '' "s/VERSION_PLACEHOLDER/$APP_VERSION/" "$APP/Contents/Info.plist"

# --- CODE SIGNING ---

echo "Removing old signature..."
codesign --remove-signature "$APP" 2>/dev/null || true

echo "Re-signing app..."
codesign --force --deep --sign - "$APP"

echo "Verifying signature..."
codesign --verify --deep --strict "$APP"

# --- INSTALL STEP (VERSIONED) ---

INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

FINAL_PATH="$INSTALL_DIR/$APP_VERSION.app"

echo "Installing to $FINAL_PATH..."

rm -rf "$FINAL_PATH"
mv "$APP" "$FINAL_PATH"

echo "Done."
echo "Installed at: $FINAL_PATH"
