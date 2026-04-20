#!/bin/bash
# Injured Installer Script (No Admin Required, Cleaned)

set -e

echo "=== Whisky Installer ==="

# --- 1️⃣ Ensure ~/bin exists ---
BIN_DIR="$HOME/bin"
mkdir -p "$BIN_DIR"

# --- 2️⃣ Detect shell and add ~/bin to PATH ---
if [ -n "$ZSH_VERSION" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_RC="$HOME/.bash_profile"
else
    SHELL_RC="$HOME/.profile"
fi

touch "$SHELL_RC"

if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$SHELL_RC"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$SHELL_RC"
    echo "Added $BIN_DIR to PATH in $SHELL_RC"
fi

export PATH="$HOME/bin:$PATH"

# --- 3️⃣ Download injured.app ---
# ⚠️ Replace 'injured.zip' below if the actual asset name differs
APP_URL="https://github.com/Suspendednetwork/Whisky/releases/download/reles/injured.zip"
APP_TMP="$(mktemp -d)"

echo "Downloading injured..."
curl -fL "$APP_URL" -o "$APP_TMP/injured.zip"

echo "Unzipping injured..."
unzip -q "$APP_TMP/injured.zip" -d "$APP_TMP"

mkdir -p "$HOME/Applications"
if [ -d "$HOME/Applications/injured.app" ]; then
    echo "injured.app already exists, replacing..."
    rm -rf "$HOME/Applications/injured.app"
fi

mv "$APP_TMP/injured.app" "$HOME/Applications/"

echo "Installation complete!"
echo "Restart your terminal or run 'source $SHELL_RC'"
