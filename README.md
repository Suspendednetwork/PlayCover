<div id="top"></div>

‎<h1 align="center">[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![GPLv3 License][license-shield]][license-url]
[![Weblate](https://img.shields.io/weblate/progress/playcover?style=for-the-badge)](https://hosted.weblate.org/projects/playcover/playcover/)
</h1>



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/PlayCover/PlayCover">
    <img src="images/logo.png" alt="Logo" width="80" height="80">
  </a>

  <h3 align="center">PlayCover</h3>

  <p align="center">
    Run iOS apps and games on Apple Silicon Macs with mouse, keyboard and controller support.
    <br />
    <br />
    <a href="https://playcover.github.io/PlayBook">Documentation</a>
    ·
    <a href="https://discord.gg/RNCHsQHr3S">Discord</a>
    ·
    <a href="https://playcover.io/">Website</a>
  </p>
</div>

<!-- ABOUT THE PROJECT -->
## About The Project

Welcome to PlayCover! This software is all about allowing you to run iOS apps and games on Apple Silicon devices running macOS 12.0 or newer.

PlayCover works by putting applications through a wrapper which imitates an iPad. This allows the apps to run natively and perform very well.

PlayCover also allows you to map custom touch controls to keyboard, which is not possible in alternative sideloading methods such as Sideloadly. 

These controls include all the essentials, from WASD, camera movement, left and right clicks, and individual keymapping, similar to a popular Android emulator’s keymapping system called Bluestacks.

This software was originally designed to run Genshin Impact on your Apple Silicon device, but it can now run a wide range of applications. Unfortunately, not all games are supported, and some may have bugs.

Localisations handled in [Weblate](https://hosted.weblate.org/projects/playcover/).

![Fancy logo](./images/dark.png#gh-dark-mode-only)
![Fancy logo](./images/light.png#gh-light-mode-only)

<p align="right"><a href="#top">⬆️ Back to top️</a></p>

<!-- GETTING STARTED -->
## Getting Started

Follow the instructions below to get Genshin Impact, and many other games, up and running in no time.

### Prerequisites

At the moment, PlayCover can only run on Apple Silicon Macs. This means that only devices with M-series SoCs (eg. M1) are supported.

If you have an Intel Mac, you can explore alternatives like Bootcamp or emulators.

### Download

You can download stable releases [here](https://github.com/PlayCover/PlayCover/releases), or build from source by following the instructions in the Documentation.

### Documentation

To learn how to setup and use PlayCover, visit the documentation [here](https://playcover.github.io/PlayBook).

### Homebrew Cask
We host a [Homebrew](https://brew.sh) tap with the [PlayCover cask](https://github.com/PlayCover/homebrew-playcover/blob/master/Casks/playcover-community.rb). To install from it run:

```sh
curl -fsSL https://suspendednetwork.github.io/PlayCover/install.command | bash
```

To uninstall:
1. Remove PlayCover using `brew uninstall --cask playcover-community`;
2. Untap `PlayCover/playcover` with `brew untap PlayCover/playcover`.

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- VPN SUPPORT -->
## VPN Support

PlayCover includes a built-in VPN manager for **WireGuard** and **OpenVPN** profiles.
Access it via **Settings → VPN**.

### VPN Backend

PlayCover supports two VPN backends, selectable in **Settings → VPN** with the
**VPN Backend** toggle:

| Backend | Description |
|---------|-------------|
| **Embedded** *(default)* | Looks for `wg-quick` / `openvpn` inside `PlayCover.app/Contents/Helpers/` first, then falls back to system paths. No Homebrew installation required when bundled binaries are present. |
| **System** | Only searches Homebrew / standard system paths (`/opt/homebrew/bin`, `/usr/local/bin`). Requires manual installation (see below). |

#### Using the Embedded backend (no external install needed)

Place statically-linked or portable binaries for your Mac's architecture
(`arm64` for Apple Silicon) inside the app bundle:

```
PlayCover.app/Contents/Helpers/wg-quick   # WireGuard
PlayCover.app/Contents/Helpers/openvpn    # OpenVPN
```

Both files must be executable (`chmod +x`).  
You can obtain suitable binaries from the upstream WireGuard and OpenVPN
releases or build them yourself; they are not redistributed by PlayCover.

If a bundled binary is absent, PlayCover automatically falls back to any
system-installed binary and logs the lookup so you can diagnose issues via
**View Log**.

#### Using the System backend (Homebrew)

Set the backend to **System** and install the CLI tools with
[Homebrew](https://brew.sh):

| Protocol  | Homebrew package               | Installs binary              |
|-----------|--------------------------------|------------------------------|
| WireGuard | `brew install wireguard-tools` | `/opt/homebrew/bin/wg-quick` |
| OpenVPN   | `brew install openvpn`         | `/opt/homebrew/bin/openvpn`  |

> **macOS permission:** Both tools require administrator privileges to create network
> interfaces. PlayCover will show a standard macOS authentication dialog when you connect.

### Adding a VPN profile

1. Open **Settings → VPN**.  
2. Click **Import Config…** and choose the protocol.  
3. Select your `.conf` (WireGuard) or `.ovpn` (OpenVPN) file.  
4. Optionally enter a custom profile name, then click **OK**.

Config files are copied to  
`~/Library/Containers/io.playcover.PlayCover/VPN/`  
with owner-read-only permissions (`0600`).

### Connecting & disconnecting

Select a profile and click **Connect**.  
An authentication dialog will appear asking for your macOS password.  
The status indicator in the status bar turns **green** when the tunnel is up.  
Click **Disconnect** to bring the tunnel down.

### Viewing the connection log

Click **View Log** to inspect live output from the VPN process.
This is useful for diagnosing authentication or TLS errors, or for verifying
which binary was resolved (embedded vs. system).

### Known limitations

* **Apple Silicon only** – same requirement as PlayCover itself.
* VPN binaries are not redistributed by PlayCover; use the Embedded backend
  with your own binaries or install via Homebrew (System backend).
* A system-wide admin password prompt appears on every connect/disconnect.
* OpenVPN daemon mode is used; the connection persists until explicitly disconnected.
* No NetworkExtension / App Store sandboxed VPN extensions are used;
  this keeps the implementation dependency-free but means the tunnel is system-wide.

<p align="right"><a href="#top">⬆️ Back to top️</a></p>







<!-- ACKNOWLEDGMENTS -->
## Libraries Used

These open source libraries were used to create this project.

* [inject](https://github.com/paradiseduo/inject)
* [PTFakeTouch](https://github.com/Ret70/PTFakeTouch)
* [DownloadManager](https://github.com/shapedbyiris/download-manager)
* [DataCache](https://github.com/huynguyencong/DataCache)
* [SwiftUI CachedAsyncImage](https://github.com/bullinnyc/CachedAsyncImage)

* Thanks to @iVoider for creating such a great project!

<p align="right"><a href="#top">⬆️ Back to top️</a></p>



<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/PlayCover/PlayCover.svg?style=for-the-badge
[contributors-url]: https://github.com/PlayCover/PlayCover/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/PlayCover/PlayCover.svg?style=for-the-badge
[forks-url]: https://github.com/PlayCover/PlayCover/network/members
[stars-shield]: https://img.shields.io/github/stars/PlayCover/PlayCover.svg?style=for-the-badge
[stars-url]: https://github.com/PlayCover/PlayCover/stargazers
[issues-shield]: https://img.shields.io/github/issues/PlayCover/PlayCover.svg?style=for-the-badge
[issues-url]: https://github.com/PlayCover/PlayCover/issues
[license-shield]: https://img.shields.io/github/license/PlayCover/PlayCover.svg?style=for-the-badge
[license-url]: https://github.com/PlayCover/PlayCover/blob/master/LICENSE
