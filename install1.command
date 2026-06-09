#!/bin/bash
set -e

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer&arch=x86-64"
else
    DOWNLOAD_URL="https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
fi

echo "Downloading Roblox..."

curl -L --fail --show-error "$DOWNLOAD_URL" -o Roblox.zip

echo "Checking file type..."

FILE_TYPE=$(file Roblox.zip)
echo "$FILE_TYPE"

# --- IMPORTANT SAFETY CHECK ---
if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP file."
    echo "Most likely the URL returned HTML or an error page."
    exit 1
fi

echo "Extracting..."
rm -rf RobloxExtract
mkdir -p RobloxExtract
unzip -q Roblox.zip -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Could not find Roblox app bundle."
    exit 1
fi

echo "Found: $APP"

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
	<string>7240735</string>

	<key>LSMinimumSystemVersion</key>
	<string>10.13</string>

	<key>NSMicrophoneUsageDescription</key>
	<string>Roblox needs access to your microphone to chat with voice.</string>

	<key>NSCameraUsageDescription</key>
	<string>Roblox needs access to your camera for beta features.</string>
</dict>
</plist>
EOF

# --- CODE SIGNING ---

echo "Removing old signature..."
codesign --remove-signature "$APP" 2>/dev/null || true

echo "Re-signing app..."
codesign --force --deep --sign - "$APP"

echo "Verifying signature..."
codesign --verify --deep --strict "$APP"

# --- INSTALL STEP ---

INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

APP_NAME=$(basename "$APP")

echo "Installing to $INSTALL_DIR/$APP_NAME..."

rm -rf "$INSTALL_DIR/$APP_NAME"
mv "$APP" "$INSTALL_DIR/"

echo "Done."
echo "Installed at: $INSTALL_DIR/$APP_NAME"
