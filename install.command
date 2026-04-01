#!/usr/bin/env bash
set -e

echo "=== Installing WireGuard CLI and Injure ==="

# --- Ensure folders exist ---
mkdir -p "$HOME/bin"
mkdir -p "$HOME/Applications"

# --- Install Homebrew locally (no sudo) ---
if [ ! -d "$HOME/homebrew" ]; then
  echo "Installing Homebrew locally..."
  mkdir -p "$HOME/homebrew"
  curl -fsSL https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOME/homebrew"
fi

# Add Homebrew to PATH for this script
export PATH="$HOME/homebrew/bin:$PATH"

# --- Install WireGuard CLI ---
if ! command -v wg >/dev/null 2>&1; then
  echo "Installing WireGuard CLI..."
  brew update || true
  brew install wireguard-tools
fi

# --- Ensure wg + wg-quick accessible in ~/bin (for your Swift app) ---
if [ -f "$HOME/homebrew/bin/wg" ]; then
  ln -sf "$HOME/homebrew/bin/wg" "$HOME/bin/wg"
fi

if [ -f "$HOME/homebrew/bin/wg-quick" ]; then
  ln -sf "$HOME/homebrew/bin/wg-quick" "$HOME/bin/wg-quick"
fi

chmod +x "$HOME/bin/wg" "$HOME/bin/wg-quick" 2>/dev/null || true

# --- Add ~/bin + Homebrew to PATH permanently ---
ZSHRC="$HOME/.zshrc"

if ! grep -q 'export PATH="$HOME/bin:$HOME/homebrew/bin:$PATH"' "$ZSHRC" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$HOME/homebrew/bin:$PATH"' >> "$ZSHRC"
fi

# --- Install Injure.app ---
APP_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
TEMP_DIR="$(mktemp -d)"

echo "Downloading Injure..."
curl -fsSL "$APP_URL" -o "$TEMP_DIR/injure.zip"

echo "Unzipping Injure..."
unzip -q "$TEMP_DIR/injure.zip" -d "$TEMP_DIR"

# Find injure.app (handles nested folders)
INJURE_APP="$(find "$TEMP_DIR" -name "injure.app" -type d | head -n1)"

if [ -z "$INJURE_APP" ]; then
  echo "❌ ERROR: injure.app not found in zip"
  rm -rf "$TEMP_DIR"
  exit 1
fi

echo "Installing Injure.app..."
mv "$INJURE_APP" "$HOME/Applications/"

# Remove quarantine (important for macOS apps)
xattr -cr "$HOME/Applications/injure.app" || true

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "✅ DONE!"
echo "Injure.app → ~/Applications"
echo "WireGuard CLI → ~/bin (wg, wg-quick)"
echo ""
echo "👉 Restart terminal OR run:"
echo "source ~/.zshrc"
