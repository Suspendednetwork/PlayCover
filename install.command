#!/bin/bash
set -e

echo "=== Installing WireGuard CLI and Injure ==="

# Create necessary directories
mkdir -p ~/Applications
mkdir -p ~/bin

# 1️⃣ Install WireGuard CLI first
echo "Installing WireGuard CLI to ~/bin..."
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-darwin-arm64"
    WG_QUICK_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-quick-darwin-arm64"
else
    WG_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-darwin-amd64"
    WG_QUICK_URL="https://github.com/WireGuard/wireguard-tools/releases/download/1.0.20230401/wg-quick-darwin-amd64"
fi

curl -L -o ~/bin/wg "$WG_URL"
curl -L -o ~/bin/wg-quick "$WG_QUICK_URL"
chmod +x ~/bin/wg ~/bin/wg-quick

# Ensure ~/bin is in PATH
if ! grep -q 'export PATH="$HOME/bin:$PATH"' ~/.zshrc 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
    echo "Added ~/bin to PATH in ~/.zshrc"
fi

echo "WireGuard CLI installed (wg, wg-quick)"

# 2️⃣ Install Injure last
echo "Downloading Injure..."
INJURE_URL="https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip"
curl -L -o /tmp/injure.zip "$INJURE_URL"

# Remove old Injure folder if exists
rm -rf ~/Applications/injure

# Unzip Injure and remove __MACOSX
echo "Extracting Injure..."
unzip -q /tmp/injure.zip -d ~/Applications
rm -rf ~/Applications/__MACOSX
rm /tmp/injure.zip

echo "Injure installed in ~/Applications"

echo "✅ Installation complete! Restart your terminal or run 'source ~/.zshrc' to use CLI"
