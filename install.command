#!/bin/bash
set -e

echo "=== Installing WireGuard CLI and Injure ==="

# --- Create local bin and Applications directories ---
mkdir -p "$HOME/bin"
mkdir -p "$HOME/Applications"

# --- Install WireGuard CLI ---
WIREGUARD_URL="https://github.com/WireGuard/wireguard-tools/archive/refs/tags/v1.0.20260223.zip"
WIREGUARD_TEMP="$(mktemp -d)"
echo "Downloading WireGuard CLI..."
curl -L -o "$WIREGUARD_TEMP/wg.zip" "$WIREGUARD_URL"

echo "Unzipping WireGuard CLI..."
unzip -q "$WIREGUARD_TEMP/wg.zip" -d "$WIREGUARD_TEMP"

# The binary location inside the zip
WG_BINARY_PATH="$WIREGUARD_TEMP/wireguard-tools-1.0.20260223/src/wg"
if [ ! -f "$WG_BINARY_PATH" ]; then
    echo "Error: WireGuard binary not found inside zip."
    exit 1
fi

echo "Moving WireGuard binary to ~/bin..."
mv "$WG_BINARY_PATH" "$HOME/bin/wg"
chmod +x "$HOME/bin/wg"

# --- Install Injure.app ---
INJURE_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
INJURE_TEMP="$(mktemp -d)"
echo "Downloading Injure..."
curl -L -o "$INJURE_TEMP/injure.zip" "$INJURE_URL"

echo "Unzipping Injure..."
unzip -q "$INJURE_TEMP/injure.zip" -d "$INJURE_TEMP"

if [ ! -d "$INJURE_TEMP/injure.app" ]; then
    echo "Error: Injure.app not found inside zip."
    exit 1
fi

echo "Moving Injure to ~/Applications..."
mv "$INJURE_TEMP/injure.app" "$HOME/Applications/"

# --- Cleanup ---
rm -rf "$WIREGUARD_TEMP" "$INJURE_TEMP"

echo "=== Installation Complete ==="
echo "Make sure ~/bin is in your PATH: export PATH=\"\$HOME/bin:\$PATH\""
