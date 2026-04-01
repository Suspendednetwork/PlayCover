#!/bin/bash

# Install Homebrew dependencies if needed
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Example: install dependencies your app needs
brew install some-dependency another-dependency

# Install injure.app
APP_DIR=~/Applications
SOURCE_DIR=~/Downloads/injure

mkdir -p "$APP_DIR"
mv "$SOURCE_DIR/injure.app" "$APP_DIR/"
rmdir "$SOURCE_DIR" 2>/dev/null || true

# Remove quarantine flags
xattr -cr "$APP_DIR/injure.app"

echo "✅ injure.app installed with dependencies in ~/Applications"
