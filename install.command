#!/bin/bash
set -e

echo "=== Installing WireGuard CLI and Injure ==="

# Ensure bin exists
mkdir -p "$HOME/bin"

# Use absolute path for curl output
WG_BIN="$HOME/bin/wg"
WG_QUICK_BIN="$HOME/bin/wg-quick"

ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-darwin-arm64"
    WG_QUICK_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-quick-darwin-arm64"
else
    WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-darwin-amd64"
    WG_QUICK_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-quick-darwin-amd64"
fi

echo "Downloading WireGuard CLI..."
curl -L "$WG_URL" -o "$WG_BIN"
curl -L "$WG_QUICK_URL" -o "$WG_QUICK_BIN"
chmod +x "$WG_BIN" "$WG_QUICK_BIN"

# Add ~/bin to PATH if not already
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
    echo "Added ~/bin to PATH in ~/.zshrc"
fi

echo "WireGuard CLI installed (wg, wg-quick)"

# Injure install
echo "Downloading Injure..."
curl -L -o "/tmp/injure.zip" "https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
rm -rf "$HOME/Applications/injure"
unzip -q /tmp/injure.zip -d "$HOME/Applications"
rm -rf "$HOME/Applications/__MACOSX" /tmp/injure.zip

echo "Injure installed in ~/Applications"
echo "✅ Installation complete! Restart terminal or run 'source ~/.zshrc' to use CLI"
