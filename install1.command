#!/bin/bash
set -e

echo "Fetching Roblox MacPlayer version..."

# --- GET VERSION HASH ---
ROBLOX_VERSION=$(
curl -fsSL "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE" \
| python3 -c "import sys, json; print(json.load(sys.stdin)['clientVersionUpload'])"
)

if [ -z "$ROBLOX_VERSION" ]; then
    echo "Failed to fetch Roblox version"
    exit 1
fi

echo "Detected version: $ROBLOX_VERSION"

# --- CLEAN ---
rm -rf Roblox.app RobloxExtract /tmp/roblox.zip

# --- BUILD DOWNLOAD URL (REAL CDN METHOD) ---
DOWNLOAD_URL="https://setup.rbxcdn.com/mac/$ROBLOX_VERSION-RobloxMac.zip"

echo "Downloading from:"
echo "$DOWNLOAD_URL"

curl -L --fail --show-error "$DOWNLOAD_URL" -o /tmp/roblox.zip

# --- VALIDATE ZIP ---
FILE_TYPE=$(file /tmp/roblox.zip)

if ! echo "$FILE_TYPE" | grep -q "Zip archive data"; then
    echo "ERROR: Download is not a valid ZIP (got HTML instead)"
    exit 1
fi

# --- EXTRACT ---
mkdir -p RobloxExtract
unzip -q /tmp/roblox.zip -d RobloxExtract

APP=$(find RobloxExtract -name "*.app" | head -n 1)

if [ -z "$APP" ]; then
    echo "Could not find Roblox app"
    exit 1
fi

echo "Found app: $APP"

# --- INSTALL TO APPLICATIONS ---
INSTALL_DIR="$HOME/Applications"
mkdir -p "$INSTALL_DIR"

rm -rf "$INSTALL_DIR/Roblox.app"
mv "$APP" "$INSTALL_DIR/Roblox.app"

echo "Installed successfully to $INSTALL_DIR/Roblox.app"
