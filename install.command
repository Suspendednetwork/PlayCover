#!/bin/bash
# One-click Injure + WireGuard install without sudo

# Injure
curl -L https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip -o ~/Downloads/injure.zip
unzip -q ~/Downloads/injure.zip -d ~/Applications
rm ~/Downloads/injure.zip
rm -rf ~/Applications/__MACOSX

# WireGuard
curl -L https://download.wireguard.com/wireguard-macos/WireGuard.app.zip -o ~/Downloads/WireGuard.app.zip
unzip -q ~/Downloads/WireGuard.app.zip -d ~/Applications
rm ~/Downloads/WireGuard.app.zip

# CLI link
mkdir -p ~/bin
ln -sf /Applications/WireGuard.app/Contents/MacOS/wg ~/bin/wg
grep -qxF 'export PATH="$HOME/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

echo "Done! Injure installed in ~/Applications, WireGuard CLI ready as 'wg'."
