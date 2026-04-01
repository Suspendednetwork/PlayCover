#!/bin/bash

set -e

APP_NAME="injure"
APP_DIR="$HOME/Applications"
USER_BIN="$HOME/bin"   # Local bin folder for non-sudo executables
ZIP_FILE="$HOME/$APP_NAME.zip"

echo "🚀 Installing $APP_NAME..."

# 1️⃣ Move injure.app to Applications
if [ -d "$APP_NAME.app" ]; then
    mkdir -p "$APP_DIR"
    mv -f "$APP_NAME.app" "$APP_DIR/"
    echo "✅ $APP_NAME.app moved to $APP_DIR"
else
    echo "⚠️ $APP_NAME.app not found in current folder"
fi

# 2️⃣ Delete injure.zip if it exists
if [ -f "$ZIP_FILE" ]; then
    rm -f "$ZIP_FILE"
    echo "🗑️ Deleted $ZIP_FILE"
fi

# 3️⃣ Hide any __MACOSX folders
if [ -d "__MACOSX" ]; then
    rm -rf "__MACOSX"
    echo "🙈 Hidden __MACOSX folder"
fi

# 4️⃣ Install WireGuard CLI locally (no sudo)
WG_BIN="$USER_BIN/wg"
mkdir -p "$USER_BIN"
if [ ! -f "$WG_BIN" ]; then
    echo "⚡ Installing WireGuard CLI locally..."
    curl -L -o "$WG_BIN" https://git.zx2c4.com/wireguard-tools/snapshot/wg-1.0.20230327.tar.xz
    chmod +x "$WG_BIN"
    echo "✅ WireGuard CLI installed at $WG_BIN"
else
    echo "✅ WireGuard CLI already installed at $WG_BIN"
fi

# 5️⃣ OpenVPN note
echo "⚠️ OpenVPN CLI requires Homebrew for installation. To install, you’ll need Homebrew or an alternative method."

# 6️⃣ Update PATH if needed
if [[ ":$PATH:" != *":$USER_BIN:"* ]]; then
    echo "🔧 Add $USER_BIN to your PATH to use wg easily:"
    echo "export PATH=\"\$PATH:$USER_BIN\""
fi

echo "🎉 Installation complete!"
