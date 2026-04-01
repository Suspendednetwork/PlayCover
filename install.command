#!/usr/bin/env bash
set -e

echo "=== Installing WireGuard CLI and Injure ==="

# --- Setup local bin ---
mkdir -p "$HOME/bin"
export PATH="$HOME/bin:$HOME/homebrew/bin:$PATH"

# --- Install Homebrew locally if missing ---
if [ ! -d "$HOME/homebrew" ]; then
  echo "Installing Homebrew locally..."
  mkdir -p "$HOME/homebrew"
  curl -fsSL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOME/homebrew"
fi

# Ensure Homebrew bin is first
export PATH="$HOME/homebrew/bin:$PATH"

# --- Install WireGuard CLI via Homebrew ---
if ! command -v wg >/dev/null 2>&1; then
  echo "Installing WireGuard CLI..."
  brew update || true
  brew install wireguard-tools || {
    echo "⚠️ WireGuard CLI failed to install via Homebrew"
  }
fi

# --- Install Injure.app ---
APP_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
TEMP_DIR="$(mktemp -d)"
echo "Downloading Injure..."
curl -fsSL "$APP_URL" -o "$TEMP_DIR/injure.zip"

echo "Unzipping Injure..."
unzip -q "$TEMP_DIR/injure.zip" -d "$TEMP_DIR"

echo "Moving Injure to ~/Applications..."
mkdir -p "$HOME/Applications"
mv "$TEMP_DIR/injure.app" "$HOME/Applications/"

# --- Cleanup ---
rm -rf "$TEMP_DIR"

echo "Done! Injure installed in ~/Applications."
echo "WireGuard CLI installed via Homebrew. Ensure PATH includes ~/homebrew/bin if not already."
echo "Restart terminal or run 'export PATH=\"$HOME/homebrew/bin:$PATH\"' to use CLI."
