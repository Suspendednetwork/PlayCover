#!/bin/bash

# Download Roblox MacPlayer via RDD and setup
# This opens RDD in browser, waits for download, then auto-installs

echo "🚀 Roblox MacPlayer Installer for PlayCover"
echo ""
echo "This script will:"
echo "  1. Open RDD (Roblox Deployment Downloader) in your browser"
echo "  2. Wait for you to download Roblox"
echo "  3. Automatically extract and install it"
echo ""
echo "Press Enter to continue..."
read

# Open RDD in browser
echo "Opening browser to RDD..."
open "https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "Browser opened. In the RDD page:"
echo ""
echo "  1. Wait for the page to fully load (30-60 seconds)"
echo "  2. Click the 'Download' button"
echo "  3. The ZIP will download to ~/Downloads/"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Waiting for download... (checking every 5 seconds)"
echo ""

# Wait for ZIP to appear in Downloads
MAX_WAIT=600  # 10 minutes
WAIT_TIME=0

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    ZIP=$(find ~/Downloads -maxdepth 1 \( -name "Roblox*.zip" -o -name "*RobloxPlayer*.zip" \) -newermt "1 minute ago" 2>/dev/null | head -1)
    
    if [ -n "$ZIP" ]; then
        echo "✓ Found download: $(basename "$ZIP")"
        echo ""
        break
    fi
    
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
    echo -n "."
done

if [ -z "$ZIP" ]; then
    echo ""
    echo "⏱️ Timeout waiting for download."
    echo ""
    echo "Manual setup:"
    echo "  1. Download from: https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
    echo "  2. Run: bash ~/setup_roblox.sh ~/Downloads/Roblox.zip"
    exit 1
fi

echo ""
echo "Running setup..."
bash "$(dirname "$0")/setup_roblox.sh" "$ZIP"
