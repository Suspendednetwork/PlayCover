#!/bin/bash

set -e

APP_DIR="$HOME/Applications"
ZIP_FILE="$APP_DIR/injure.zip"

echo "=== Installing injure.app ==="

# Create Applications folder
mkdir -p "$APP_DIR"

# Download app
curl -L https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip -o "$ZIP_FILE"

# Extract (ignore __MACOSX)
unzip -o "$ZIP_FILE" -d "$APP_DIR" -x "__MACOSX/*"

# Remove quarantine
xattr -cr "$APP_DIR/injure.app"

# Cleanup
rm -f "$ZIP_FILE"
rm -rf "$APP_DIR/__MACOSX"

# Verify
if [ -d "$APP_DIR/injure.app" ]; then
  echo "✅ injure.app installed in ~/Applications"
else
  echo "❌ Install failed"
  exit 1
fi

echo "=== Setting up Homebrew (no admin) ==="

# Install local Homebrew if missing
if [ ! -d "$HOME/homebrew" ]; then
  mkdir -p "$HOME/homebrew"
  curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOME/homebrew"
fi

# Add to PATH
export PATH="$HOME/homebrew/bin:$PATH"

# Persist PATH
if ! grep -q 'homebrew/bin' "$HOME/.zprofile"; then
  echo 'export PATH="$HOME/homebrew/bin:$PATH"' >> "$HOME/.zprofile"
fi

echo "=== Installing dependencies ==="

# Update (don't fail if slow)
brew update || true

# Install VPN tools (don't block install if they fail)
brew install wireguard-tools --force-bottle || true
brew install openvpn --force-bottle || true

echo "🎉 Done! injure.app + VPN tools installed"
