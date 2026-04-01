#!/bin/bash
set -euo pipefail

echo "=== Installing WireGuard CLI and Injure ==="

# --- Ensure ~/bin and ~/Applications exist ---
mkdir -p "$HOME/bin"
mkdir -p "$HOME/Applications"

# --- 1. Install WireGuard CLI ---
WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/v1.0.20231011/wg-1.0.20231011-darwin-arm64.zip"
WG_TMP="$HOME/Downloads/wg_temp"
mkdir -p "$WG_TMP"

echo "Downloading WireGuard CLI..."
curl -L "$WG_URL" -o "$WG_TMP/wg.zip"

echo "Unzipping WireGuard CLI..."
unzip -o "$WG_TMP/wg.zip" -d "$WG_TMP"

echo "Moving wg binaries to ~/bin..."
mv "$WG_TMP/wg" "$HOME/bin/wg"
mv "$WG_TMP/wg-quick" "$HOME/bin/wg-quick"
chmod +x "$HOME/bin/wg" "$HOME/bin/wg-quick"

rm -rf "$WG_TMP"

# --- 2. Install Injure.app ---
INJURE_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
INJURE_TMP="$HOME/Downloads/injure_temp"
mkdir -p "$INJURE_TMP"

echo "Downloading Injure..."
curl -L "$INJURE_URL" -o "$INJURE_TMP/injure.zip"

echo "Unzipping Injure..."
unzip -o "$INJURE_TMP/injure.zip" -d "$INJURE_TMP"

# Remove __MACOSX if it exists
rm -rf "$INJURE_TMP/__MACOSX"

echo "Moving Injure.app to ~/Applications..."
mv "$INJURE_TMP/injure.app" "$HOME/Applications/"

rm -rf "$INJURE_TMP"

# --- 3. Update PATH in .zshrc ---
ZSHRC="$HOME/.zshrc"
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$ZSHRC" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$ZSHRC"
    echo "Added ~/bin to PATH in $ZSHRC"
fi

echo "=== Done! ==="
echo "WireGuard CLI installed in ~/bin (wg, wg-quick)."
echo "Injure.app installed in ~/Applications."
echo "Restart your terminal or run 'source ~/.zshrc' to use wg and wg-quick."
