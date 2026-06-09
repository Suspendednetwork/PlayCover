#!/bin/bash

set -e

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    DOWNLOAD_URL="https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer&arch=x86-64"
else
    DOWNLOAD_URL="https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
fi

echo "Downloading Roblox..."
curl -L "$DOWNLOAD_URL" -o Roblox.zip

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

# Rename binaries if present
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
	<key>ATSApplicationFontsPath</key>
	<string>content/fonts</string>
	<key>BreakpadReportInterval</key>
	<string>0</string>
	<key>BreakpadSendAndExit</key>
	<string>NO</string>
	<key>BreakpadSkipConfirm</key>
	<string>YES</string>
	<key>BreakpadVendor</key>
	<string>Roblox</string>

	<key>CFBundleDevelopmentRegion</key>
	<string>English</string>

	<key>CFBundleExecutable</key>
	<string>r</string>

	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIconName</key>
	<string>AppIcon</string>

	<key>CFBundleIdentifier</key>
	<string>com.leonel.lovesyou</string>

	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>

	<key>CFBundleName</key>
	<string>Roblox</string>

	<key>CFBundlePackageType</key>
	<string>APPL</string>

	<key>CFBundleShortVersionString</key>
	<string>0.724.0.7240735</string>

	<key>CFBundleSignature</key>
	<string>????</string>

	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Viewer</string>
			<key>CFBundleURLName</key>
			<string>Roblox Player URL</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>roblox-player</string>
				<string>roblox</string>
			</array>
		</dict>
	</array>

	<key>CFBundleVersion</key>
	<string>7240735</string>

	<key>LSMinimumSystemVersion</key>
	<string>10.13</string>

	<key>LSMultipleInstancesProhibited</key>
	<true/>

	<key>LSUIElement</key>
	<true/>

	<key>MetalCaptureEnabled</key>
	<false/>

	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>

	<key>NSCameraUsageDescription</key>
	<string>Roblox needs access to your camera for beta features.</string>

	<key>NSHighResolutionCapable</key>
	<true/>

	<key>NSMainNibFile</key>
	<string>MainMenu</string>

	<key>NSMicrophoneUsageDescription</key>
	<string>Roblox needs access to your microphone to chat with voice.</string>

	<key>NSPrincipalClass</key>
	<string>NSApplication</string>

	<key>NSSupportsSuddenTermination</key>
	<false/>

	<key>RbxBaseUrl</key>
	<string>https://www.roblox.com/</string>

	<key>RbxInstallHost</key>
	<string>setup.roblox.com</string>

	<key>RbxStartPath</key>
	<string></string>

	<key>UIAppFonts</key>
	<array>
		<string>BuilderSans-Medium.otf</string>
	</array>
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

echo "Installed successfully."
echo "Location: $INSTALL_DIR/$APP_NAME"
