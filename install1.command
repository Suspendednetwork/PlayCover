#!/bin/bash
set -e

# Install Roblox MacPlayer for PlayCover
# This script disables Python SSL verification and runs the installer

echo "🚀 Roblox Installer for macOS"
echo ""

# Create Python script inline with SSL verification disabled
PYTHON_SCRIPT=$(cat <<'PYTHON_EOF'
import os, sys, subprocess, json, urllib.request, urllib.error, shutil, tempfile, ssl
from typing import Optional

# Disable SSL verification BEFORE any network calls
ssl._create_default_https_context = ssl._create_unverified_context

class RobloxInstaller:
    def __init__(self, debug: bool = False):
        self.debug = debug
        self.temp_dir = tempfile.mkdtemp(prefix="roblox_")
        self.version = None
        
    def log(self, msg: str, level: str = "INFO"):
        prefix = {"INFO": "✓", "WARN": "⚠️ ", "ERROR": "❌", "DEBUG": "🔍"}.get(level, "→")
        print(f"{prefix} {msg}")
        
    def debug_log(self, msg: str):
        if self.debug:
            self.log(msg, "DEBUG")
    
    def run_cmd(self, cmd: list, check: bool = True) -> str:
        self.debug_log(f"Running: {' '.join(cmd)}")
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=check)
            if result.stdout:
                self.debug_log(f"Output: {result.stdout[:200]}")
            return result.stdout.strip()
        except subprocess.CalledProcessError as e:
            self.log(f"Command failed: {e.stderr}", "ERROR")
            raise
    
    def fetch_version(self) -> str:
        self.log("Fetching latest Roblox version...")
        url = "https://clientsettings.roblox.com/v2/client-version/MacPlayer/channel/LIVE"
        try:
            with urllib.request.urlopen(url, timeout=10) as response:
                data = json.loads(response.read().decode())
                version = data.get("clientVersionUpload", "")
                if not version:
                    raise ValueError("No clientVersionUpload in response")
                self.version = version
                self.log(f"Version: {version}")
                return version
        except Exception as e:
            self.log(f"Failed to fetch version: {e}", "ERROR")
            raise
    
    def get_download_url_from_rdd(self) -> Optional[bytes]:
        self.log("Attempting to resolve download URL via RDD pattern...")
        try:
            rdd_url = "https://rdd.latte.to/?channel=LIVE&binaryType=MacPlayer"
            headers = {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                'Accept': 'application/octet-stream',
                'Referer': 'https://rdd.latte.to/'
            }
            req = urllib.request.Request(rdd_url, headers=headers)
            self.debug_log(f"Requesting: {rdd_url}")
            
            with urllib.request.urlopen(req, timeout=15) as response:
                content_type = response.headers.get('Content-Type', '')
                content_length = response.headers.get('Content-Length', 'unknown')
                self.debug_log(f"Response headers: {dict(response.headers)}")
                
                if 'application/zip' in content_type or 'octet-stream' in content_type:
                    self.log(f"Got ZIP response (size: {content_length} bytes)")
                    return response.read()
                else:
                    self.debug_log(f"Got content-type: {content_type}")
                    return None
        except urllib.error.HTTPError as e:
            self.debug_log(f"HTTP {e.code}: {e.reason}")
            return None
        except Exception as e:
            self.debug_log(f"RDD fetch failed: {e}")
            return None
    
    def download_roblox(self) -> bytes:
        self.log("Downloading Roblox MacPlayer...")
        zip_data = self.get_download_url_from_rdd()
        if zip_data:
            self.log(f"Downloaded {len(zip_data)} bytes from RDD")
            return zip_data
        
        fallback_urls = [
            "https://setup.rbxcdn.com/mac/RobloxPlayer.zip",
            "https://roblox-client.s3.amazonaws.com/mac/RobloxPlayer.zip",
        ]
        
        for url in fallback_urls:
            try:
                self.debug_log(f"Trying fallback: {url}")
                headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'}
                req = urllib.request.Request(url, headers=headers)
                with urllib.request.urlopen(req, timeout=30) as response:
                    data = response.read()
                    self.log(f"Downloaded {len(data)} bytes from fallback URL")
                    return data
            except Exception as e:
                self.debug_log(f"Fallback failed: {e}")
        
        raise RuntimeError("All download methods failed")
    
    def extract_app(self, zip_data: bytes) -> str:
        self.log("Extracting app bundle...")
        zip_path = os.path.join(self.temp_dir, "download.zip")
        with open(zip_path, 'wb') as f:
            f.write(zip_data)
        
        extract_dir = os.path.join(self.temp_dir, "extracted")
        os.makedirs(extract_dir, exist_ok=True)
        self.run_cmd(["unzip", "-q", zip_path, "-d", extract_dir])
        
        for root, dirs, files in os.walk(extract_dir):
            for d in dirs:
                if d.endswith('.app'):
                    app_path = os.path.join(root, d)
                    self.log(f"Found app: {d}")
                    return app_path
        
        raise RuntimeError("No .app bundle found in download")
    
    def modify_app(self, app_path: str):
        self.log("Modifying app bundle...")
        macos_dir = os.path.join(app_path, "Contents", "MacOS")
        
        for old_name, new_name in [("RobloxPlayer", "r"), ("RobloxPlayerInstaller", "r-installer")]:
            old_path = os.path.join(macos_dir, old_name)
            if os.path.exists(old_path):
                new_path = os.path.join(macos_dir, new_name)
                os.rename(old_path, new_path)
                self.debug_log(f"Renamed {old_name} → {new_name}")
        
        plist_path = os.path.join(app_path, "Contents", "Info.plist")
        plist_content = f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>r</string>
    <key>CFBundleIdentifier</key>
    <string>com.leonel.lovesyou</string>
    <key>CFBundleName</key>
    <string>Roblox</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>Roblox-{self.version}</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.13</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Roblox needs access to your microphone to chat with voice.</string>
    <key>NSCameraUsageDescription</key>
    <string>Roblox needs access to your camera for beta features.</string>
</dict>
</plist>
"""
        with open(plist_path, 'w') as f:
            f.write(plist_content)
        self.log("App bundle modified")
    
    def sign_app(self, app_path: str):
        self.log("Code signing app...")
        self.run_cmd(["codesign", "--remove-signature", app_path], check=False)
        self.run_cmd(["codesign", "--force", "--deep", "--sign", "-", "--timestamp=none", app_path])
        self.run_cmd(["codesign", "--verify", "--deep", "--strict", app_path], check=False)
    
    def install_app(self, app_path: str) -> str:
        self.log("Installing app...")
        apps_dir = os.path.expanduser("~/Applications")
        os.makedirs(apps_dir, exist_ok=True)
        app_name = f"Roblox-{self.version}.app"
        final_path = os.path.join(apps_dir, app_name)
        if os.path.exists(final_path):
            shutil.rmtree(final_path)
        shutil.move(app_path, final_path)
        self.log(f"Installed at: {final_path}")
        return final_path
    
    def cleanup(self):
        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
    
    def run(self) -> str:
        try:
            self.fetch_version()
            zip_data = self.download_roblox()
            app_path = self.extract_app(zip_data)
            self.modify_app(app_path)
            self.sign_app(app_path)
            final_path = self.install_app(app_path)
            return final_path
        except Exception as e:
            self.log(f"Installation failed: {e}", "ERROR")
            raise
        finally:
            self.cleanup()

if __name__ == "__main__":
    debug = "--debug" in sys.argv or "-v" in sys.argv
    try:
        installer = RobloxInstaller(debug=debug)
        final_path = installer.run()
        print()
        print("=" * 60)
        print("✅ Installation complete!")
        print("=" * 60)
        print(f"Installed at: {final_path}")
        print()
        print("To run:")
        print(f'  open "{final_path}"')
        print()
    except Exception as e:
        sys.exit(1)
PYTHON_EOF
)

# Run the Python script with SSL verification disabled
PYTHONHTTPSVERIFY=0 python3 -c "$PYTHON_SCRIPT" "$@"
