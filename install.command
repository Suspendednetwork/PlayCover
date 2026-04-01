#!/bin/bash

set -e

echo "=== Setup starting ==="

# ---- 1. Install local Homebrew ----
if [ ! -d "$HOME/homebrew" ]; then
  echo "Installing local Homebrew..."
  mkdir -p "$HOME/homebrew"
  curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C "$HOME/homebrew"
fi

export PATH="$HOME/homebrew/bin:$PATH"

if ! grep -q 'homebrew/bin' "$HOME/.zprofile"; then
  echo 'export PATH="$HOME/homebrew/bin:$PATH"' >> "$HOME/.zprofile"
fi

# ---- 2. Install wireguard-tools ----
echo "Installing wireguard-tools..."
brew update
brew install wireguard-tools

# ---- 3. Ensure ~/Applications exists ----
APP_DIR="$HOME/Applications"
ZIP_FILE="$APP_DIR/injure.zip"

echo "Ensuring ~/Applications exists..."
mkdir -p "$APP_DIR"

# ---- 4. Download release ----
echo "Downloading latest release..."
curl -L https://github.com/Suspendednetwork/PlayCover/releases/latest/download/injure.zip -o "$ZIP_FILE"

# ---- 5. Extract ----
echo "Extracting..."
unzip -o "$ZIP_FILE" -d "$APP_DIR"

# ---- 6. Fix nesting if needed ----
if [ ! -d "$APP_DIR/injure.app" ]; then
  echo "Fixing nested app location..."
  FOUND_APP=$(find "$APP_DIR" -name "injure.app" -type d | head -n 1)
  if [ -n "$FOUND_APP" ]; then
    mv "$FOUND_APP" "$APP_DIR/"
  fi
fi

# ---- 7. Remove quarantine ----
echo "Removing quarantine attributes..."
xattr -cr "$APP_DIR/injure.app"

# ---- 8. Cleanup ----
rm "$ZIP_FILE"

echo "=== Done! ==="
echo "injure.app installed in ~/Applications"
