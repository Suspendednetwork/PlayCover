#!/bin/bash
# PlayCover Install Script (No Admin Required, Fixed)

set -e

echo "=== PlayCover Installer ==="

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

# --- 3️⃣ Download WireGuard CLI ---
WG_URL="https://github.com/WireGuard/wireguard-tools/archive/refs/tags/v1.0.20260223.zip"
WG_TMP="$(mktemp -d)"
echo "Downloading WireGuard CLI..."
curl -fsSL "$WG_URL" -o "$WG_TMP/wg.zip"

echo "Unzipping WireGuard CLI..."
unzip -q "$WG_TMP/wg.zip" -d "$WG_TMP"

# Correct path inside GitHub zip
WG_BIN=$(find "$WG_TMP/wireguard-tools-1.0.20260223/src" -type f -name wg | head -n 1)
WG_QUICK_BIN=$(find "$WG_TMP/wireguard-tools-1.0.20260223/src" -type f -name wg-quick | head -n 1)

if [ -f "$WG_BIN" ] && [ -f "$WG_QUICK_BIN" ]; then
    mv "$WG_BIN" "$BIN_DIR/wg"
    mv "$WG_QUICK_BIN" "$BIN_DIR/wg-quick"
    chmod +x "$BIN_DIR/wg" "$BIN_DIR/wg-quick"
    echo "WireGuard CLI installed to $BIN_DIR"
else
    echo "WireGuard binary not found — manual install may be required"
fi

# --- 4️⃣ Download Injure.app ---
APP_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
APP_TMP="$(mktemp -d)"
echo "Downloading Injure..."
curl -fsSL "$APP_URL" -o "$APP_TMP/injure.zip"

echo "Unzipping Injure..."
unzip -q "$APP_TMP/injure.zip" -d "$APP_TMP"

mkdir -p "$HOME/Applications"
if [ -d "$HOME/Applications/injure.app" ]; then
    echo "Injure.app already exists, replacing..."
    rm -rf "$HOME/Applications/injure.app"
fi
mv "$APP_TMP/injure.app" "$HOME/Applications/"

echo "Installation complete!"
echo "Restart your terminal or run 'source $SHELL_RC' to use 'wg' from anywhere."
