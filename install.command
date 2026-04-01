#!/bin/bash

# --- Setup directories ---
BIN_DIR="$HOME/bin"
APP_DIR="$HOME/Applications"
mkdir -p "$BIN_DIR" "$APP_DIR"

# --- Add ~/bin to PATH if not already ---
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    echo "Adding $BIN_DIR to PATH..."
    SHELL_RC="$HOME/.zshrc"
    # Fallback for bash users
    if [ ! -f "$SHELL_RC" ]; then
        SHELL_RC="$HOME/.bash_profile"
    fi
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
    export PATH="$BIN_DIR:$PATH"
fi

# --- Install WireGuard CLI ---
WG_URL="https://github.com/WireGuard/wireguard-tools/archive/refs/tags/v1.0.20260223.zip"
TEMP_DIR="$(mktemp -d)"
echo "Downloading WireGuard CLI..."
curl -fsSL "$WG_URL" -o "$TEMP_DIR/wg.zip"

echo "Unzipping WireGuard CLI..."
unzip -q "$TEMP_DIR/wg.zip" -d "$TEMP_DIR"
WG_BIN_SRC="$TEMP_DIR/wireguard-tools-1.0.20260223/src/wg"
if [ -f "$WG_BIN_SRC" ]; then
    echo "Installing WireGuard CLI to $BIN_DIR..."
    mv "$WG_BIN_SRC" "$BIN_DIR/wg"
    chmod +x "$BIN_DIR/wg"
else
    echo "WireGuard binary not found in zip!"
fi

# --- Install Injure.app ---
INJURE_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
echo "Downloading Injure..."
curl -fsSL "$INJURE_URL" -o "$TEMP_DIR/injure.zip"

echo "Unzipping Injure..."
unzip -q "$TEMP_DIR/injure.zip" -d "$TEMP_DIR"

if [ -d "$TEMP_DIR/injure.app" ]; then
    echo "Moving Injure to $APP_DIR..."
    mv "$TEMP_DIR/injure.app" "$APP_DIR/"
else
    echo "Injure.app not found in zip!"
fi

# --- Cleanup ---
rm -rf "$TEMP_DIR"

echo "Installation complete!"
echo "You may need to restart your Terminal or run 'source ~/.zshrc' (or ~/.bash_profile) to use 'wg' from anywhere."
