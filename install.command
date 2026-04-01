#!/bin/bash
set -e

echo "=== Installing WireGuard CLI and Injure ==="

# 1️⃣ Ensure ~/bin exists before installing CLI
mkdir -p "$HOME/bin"

# Determine architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-darwin-arm64"
    WG_QUICK_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-quick-darwin-arm64"
else
    WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-darwin-amd64"
    WG_QUICK_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-quick-darwin-amd64"
fi

echo "Downloading WireGuard CLI..."
curl -L -o "$HOME/bin/wg" "$WG_URL"
curl -L -o "$HOME/bin/wg-quick" "$WG_QUICK_URL"
chmod +x "$HOME/bin/wg" "$HOME/bin/wg-quick"

# Ensure ~/bin is in PATH
if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
    echo "Added ~/bin to PATH in ~/.zshrc"
fi

echo "WireGuard CLI installed (wg, wg-quick)"

# 2️⃣ Install Injure
echo "Downloading Injure..."
curl -L -o "/tmp/injure.zip" "https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"

# Remove old Injure folder if exists
rm -rf "$HOME/Applications/injure"

# Unzip Injure and remove __MACOSX
echo "Extracting Injure..."
unzip -q /tmp/injure.zip -d "$HOME/Applications"
rm -rf "$HOME/Applications/__MACOSX"
rm /tmp/injure.zip

echo "Injure installed in ~/Applications"

echo "✅ Installation complete! Restart your terminal or run 'source ~/.zshrc' to use CLI"
