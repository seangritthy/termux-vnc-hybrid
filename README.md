# 🚀 Termux VNC Hybrid Client & PRoot Debian Desktop Server

> Full PRoot Debian XFCE4 Desktop Environment & Dual Engine VNC Client (Native RFB + noVNC Web Engine) for Termux on Android with Debian Terminal (`xfce4-terminal`), Firefox ESR, and One-Click System Updater.

![Version](https://img.shields.io/badge/version-2.3.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-orange.svg)

---

## ⚡ Quick 1-Line Installation in Termux

Open your **Termux** app and paste this single command:

```bash
curl -sSL https://raw.githubusercontent.com/seangritthy/termux-vnc-hybrid/main/install.sh | bash
```

---

## ✨ What's New in v2.3.0

- 🛡️ **VNC Auto-Disconnect Prevention**: Termux CPU wake-lock acquired on startup to prevent Android CPU & Wi-Fi sleep.
- ⚡ **Zero-Timeout Idle Mode**: Added `-IdleTimeout 0` and `-MaxIdleTime 0` flags to TigerVNC server to keep remote desktop active indefinitely.
- 💓 **WebSocket Heartbeat**: Added `--heartbeat 30` WebSocket ping to noVNC proxy to prevent socket drops when idle.
- 🖥️ **Screen Saver & DPMS Blanking Disabled**: Auto-disables X11 screen blanking, DPMS power management, and screensaver lock in `xstartup`.
- 🐧 **PRoot-Distro Debian Integration**: Runs full Debian Linux environment inside VNC with glibc, apt, and desktop GUI.
- 💻 **Debian Terminal Included**: Features pre-installed `xfce4-terminal` inside VNC desktop with full Debian root access (`root@debian:~#`).
- 🌐 **Firefox ESR Web Browser**: Pre-installed Firefox browser in Debian for smooth browsing inside VNC.
- 🔄 **Built-in System & Debian Updater**: One command `vnc update` (or `~/updater.sh`) upgrades all Termux packages, PRoot Debian packages, noVNC proxy, and desktop launchers.
- 🐚 **Termux CLI Command**: Type `debian` directly in Termux terminal anytime to enter the Debian shell.

---

## 🎮 How to Use in Termux

Once installed, manage VNC & Debian anytime using these simple commands:

| Command | Action |
| :--- | :--- |
| `vnc` or `vnc start` | Starts TigerVNC server (`5901`) & noVNC web proxy (`6080`) serving Debian XFCE Desktop |
| `vnc status` | Displays server status, IP connection info & PRoot Debian status |
| `vnc update` | Runs automatic system updater for Termux, Debian packages & VNC |
| `vnc stop` | Stops all VNC processes and cleans up lock files |
| `debian` | Directly logs into the Debian Linux terminal shell inside Termux |

---

## 📱 Connecting to Desktop & Opening Debian Terminal

### Option A: VNC Hybrid Client Android App (Recommended)
1. The installer automatically copies the APK to `/sdcard/Download/vnc-hybrid-client.apk` and opens the installer.
2. Open **VNC Hybrid Client** on your phone.
3. Tap **noVNC (6080)** or **RFB Native (5901)** for instant 1-tap connection!

### Option B: Web Browser (noVNC)
Open your phone's browser (or any PC on the same Wi-Fi) and go to:
```text
http://127.0.0.1:6080/vnc.html?autoconnect=true&password=vnc123
```

### 💻 Launching Debian Terminal & Apps Inside VNC
Once connected to VNC Desktop:
- Double-click **"Debian Terminal"** on the desktop screen to open Debian's `xfce4-terminal`.
- Double-click **"Firefox Web Browser (Debian)"** to launch web browser.
- Open applications menu in top-left to access all installed Debian apps.

---

## 🛠️ Rebuilding the Android APK in Termux

If you make modifications to the Java code or UI:

```bash
cd ~/termux-vnc-hybrid/vnc_apk_project
./build_apk.sh
```
This script uses AAPT, `javac`, `d8`, `zipalign`, and `apksigner` to create a signed, production APK.

---

## 📁 Repository Structure

```text
termux-vnc-hybrid/
├── install.sh                  # Automated Termux & PRoot Debian installer
├── updater.sh                  # One-click system, Debian & VNC desktop updater
├── vnc.sh                      # Core VNC server control script
├── vncmanager.sh               # VNC status manager
├── bin/
│   └── vnc-hybrid-client.apk  # Pre-compiled v2.2.0 Android APK release
└── vnc_apk_project/            # Full Android project source code & build script
    ├── AndroidManifest.xml
    ├── build_apk.sh
    ├── res/
    └── src/
```

---

## 📄 License
Released under the [MIT License](LICENSE).
