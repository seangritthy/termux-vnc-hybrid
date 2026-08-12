# 🚀 Termux VNC Hybrid Client & Desktop Server

> Full XFCE4 Desktop Environment & Dual Engine VNC Client (Native RFB + noVNC Web Engine) for Termux on Android.

![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Termux-orange.svg)

---

## ⚡ Quick 1-Line Installation in Termux

Open your **Termux** app and paste this single command:

```bash
curl -sSL https://raw.githubusercontent.com/USERNAME/termux-vnc-hybrid/main/install.sh | bash
```

*(Replace `USERNAME` with your actual GitHub username).*

---

## ✨ Features

- 🖥️ **Full Graphical Desktop**: Launches XFCE4 desktop environment inside Termux.
- 📱 **Native Android App Included**: Ships with **VNC Hybrid Client v2.0** (`vnc-hybrid-client.apk`) for seamless display streaming.
- 🌐 **noVNC Web Interface**: Access your desktop through any browser with automatic auto-connect & password autofill.
- ⚡ **Global Terminal Command**: Manage everything using simple commands (`vnc`, `vnc status`, `vnc stop`).
- 🛠️ **Built-in On-Device Build System**: Rebuild the Android APK directly inside Termux using AAPT & javac!

---

## 🎮 How to Use in Termux

Once installed, manage VNC anytime using the `vnc` command:

| Command | Action |
| :--- | :--- |
| `vnc` or `vnc start` | Starts TigerVNC server (`5901`) & noVNC web proxy (`6080`) |
| `vnc status` | Displays server status and active connection addresses |
| `vnc stop` | Stops all VNC processes and cleans up lock files |

---

## 📱 Connecting to Desktop

### Option A: VNC Hybrid Client Android App (Recommended)
1. The installer automatically copies the APK to `/sdcard/Download/vnc-hybrid-client.apk` and opens the installer.
2. Open **VNC Hybrid Client** on your phone.
3. Tap **noVNC (6080)** or **RFB Native (5901)** for instant 1-tap connection!

### Option B: Web Browser (noVNC)
Open your phone's browser (or any PC on the same Wi-Fi) and go to:
```text
http://127.0.0.1:6080/vnc.html?autoconnect=true&password=vnc123
```

---

## 🛠️ Rebuilding the Android APK in Termux

If you make modifications to the Java code or UI:

```bash
cd ~/vnc_apk_project
./build_apk.sh
```
This script uses AAPT, `javac`, `d8`, `zipalign`, and `apksigner` to create a signed, production APK.

---

## 📁 Repository Structure

```text
termux-vnc-hybrid/
├── install.sh                  # 1-line automated Termux installer
├── vnc.sh                      # Core VNC server control script
├── vncmanager.sh               # VNC status manager
├── bin/
│   └── vnc-hybrid-client.apk  # Pre-compiled v2.0.0 Android APK release
└── vnc_apk_project/            # Full Android project source code & build script
    ├── AndroidManifest.xml
    ├── build_apk.sh
    ├── res/
    └── src/
```

---

## 📄 License
Released under the [MIT License](LICENSE).
