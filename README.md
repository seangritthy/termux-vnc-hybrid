# 🚀 Termux VNC Hybrid Client & Desktop Server

> Full XFCE4 Desktop Environment & Dual Engine VNC Client (Native RFB + noVNC Web Engine) for Termux on Android with Built-in Web Browsing & One-Click System Updater.

![Version](https://img.shields.io/badge/version-2.1.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-orange.svg)

---

## ⚡ Quick 1-Line Installation in Termux

Open your **Termux** app and paste this single command:

```bash
curl -sSL https://raw.githubusercontent.com/seangritthy/termux-vnc-hybrid/main/install.sh | bash
```

---

## ✨ What's New in v2.1.0

- 🔄 **Built-in System Updater**: One command `vnc update` (or `~/updater.sh`) upgrades all Termux packages, browser engines, noVNC proxy, and refreshes desktop launchers.
- 🌐 **Pre-configured Web Browsers**: Includes pre-installed **Chromium** and **NetSurf** web browsers with optimized flags (`--no-sandbox`, software OpenGL rendering) for desktop web browsing inside VNC.
- 🖥️ **Desktop Shortcuts**: Automatically adds **Chromium**, **NetSurf**, and **Web Browser** icons to your XFCE Desktop screen.
- 📱 **Updated Android Client v2.1**: Recompiled APK (`vnc-hybrid-client.apk`) supporting target SDK 34 and direct desktop launcher detection.

---

## 🎮 How to Use in Termux

Once installed, manage VNC anytime using the `vnc` command:

| Command | Action |
| :--- | :--- |
| `vnc` or `vnc start` | Starts TigerVNC server (`5901`) & noVNC web proxy (`6080`) |
| `vnc status` | Displays server status, IP connection info & browser launcher |
| `vnc update` | Runs automatic system updater for packages, browsers & VNC |
| `vnc stop` | Stops all VNC processes and cleans up lock files |

---

## 📱 Connecting to Desktop & Browsing Internet

### Option A: VNC Hybrid Client Android App (Recommended)
1. The installer automatically copies the APK to `/sdcard/Download/vnc-hybrid-client.apk` and opens the installer.
2. Open **VNC Hybrid Client** on your phone.
3. Tap **noVNC (6080)** or **RFB Native (5901)** for instant 1-tap connection!

### Option B: Web Browser (noVNC)
Open your phone's browser (or any PC on the same Wi-Fi) and go to:
```text
http://127.0.0.1:6080/vnc.html?autoconnect=true&password=vnc123
```

### 🌐 Launching Web Browsers Inside VNC
Once connected to VNC Desktop:
- Double-click **"Web Browser"** or **"Chromium Web Browser"** on the desktop.
- Or open a terminal inside VNC and type `vnc-browser`.

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
├── install.sh                  # 1-line automated Termux installer
├── updater.sh                  # One-click system & VNC desktop updater
├── vnc.sh                      # Core VNC server control script
├── vncmanager.sh               # VNC status manager
├── bin/
│   └── vnc-hybrid-client.apk  # Pre-compiled v2.1.0 Android APK release
└── vnc_apk_project/            # Full Android project source code & build script
    ├── AndroidManifest.xml
    ├── build_apk.sh
    ├── res/
    └── src/
```

---

## 📄 License
Released under the [MIT License](LICENSE).
