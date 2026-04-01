#!/bin/bash
# Injure + WireGuard CLI install (no sudo)

# --- Create local bin ---
mkdir -p ~/bin

# --- Injure ---
curl -L https://github.com/Suspendednetwork/PlayCover/releases/download/injure/injure.zip -o ~/Downloads/injure.zip
unzip -q ~/Downloads/injure.zip -d ~/Applications
rm ~/Downloads/injure.zip
rm -rf ~/Applications/__MACOSX

# --- WireGuard CLI (user-local) ---
WIREGUARD_VERSION=1.0.20230401
curl -L https://www.wireguard.com/downloads/wireguard-tools-$WIREGUARD_VERSION-x86_64-apple-darwin.zip -o ~/Downloads/wg.zip
unzip -q ~/Downloads/wg.zip -d ~/Downloads/wg_temp
mv ~/Downloads/wg_temp/wg ~/bin/
mv ~/Downloads/wg_temp/wg-quick ~/bin/
rm -rf ~/Downloads/wg.zip ~/Downloads/wg_temp

# --- Ensure ~/bin is in PATH ---
[ -f ~/.zshrc ] || touch ~/.zshrc
grep -qxF 'export PATH="$HOME/bin:$PATH"' ~/.zshrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
export PATH="$HOME/bin:$PATH"

echo "Done! Injure installed in ~/Applications."
echo "WireGuard CLI installed in ~/bin (wg, wg-quick)."
echo "Restart terminal or run 'source ~/.zshrc' to use CLI."
