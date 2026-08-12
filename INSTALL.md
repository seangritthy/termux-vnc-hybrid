# 📥 How to Download, Run & Update VNC in Termux

A complete guide to downloading, installing, connecting to, and updating the **Termux VNC Desktop & Hybrid Client App** with built-in Internet Web Browsers (**Chromium** & **NetSurf**).

---

## ⚡ Method 1: 1-Line Automatic Installer (Fastest)

Open **Termux** and paste this command:

```bash
curl -sSL https://raw.githubusercontent.com/seangritthy/termux-vnc-hybrid/main/install.sh | bash
```

---

## 🛠️ Method 2: Manual Git Clone Download

If you prefer to download and inspect the repository manually before running:

```bash
# 1. Update Termux & Install Git
pkg update -y && pkg install -y git

# 2. Clone the GitHub Repository
git clone https://github.com/seangritthy/termux-vnc-hybrid.git

# 3. Enter directory & run installer
cd termux-vnc-hybrid
chmod +x install.sh
./install.sh
```

---

## 🔄 System & VNC Updater

Keep your VNC environment, web browsers, and dependencies up to date anytime:

```bash
vnc update
```
or run directly:
```bash
~/updater.sh
```

---

## 🎮 Termux Terminal Commands

After installation, control your VNC server anytime with these commands:

| Command | Action |
| :--- | :--- |
| `vnc` or `vnc start` | Starts TigerVNC server (`5901`) & noVNC web proxy (`6080`) |
| `vnc status` | Displays current VNC running status, IP address & browser info |
| `vnc stop` | Stops VNC server and cleans up session locks |
| `vnc update` | Updates system packages, browsers, VNC scripts & shortcuts |

---

## 🌐 Browsing the Internet in VNC

1. Connect to VNC (via **VNC Hybrid Client app** or **noVNC web browser**).
2. Double-click the **"Web Browser"** or **"Chromium Web Browser"** icon on the desktop.
3. Browse any website on the internet seamlessly!

---

## 📱 How to Connect to Desktop

### 1. Android App (VNC Hybrid Client v2.0)
* The installer automatically copies `vnc-hybrid-client.apk` to your `/sdcard/Download/` directory and prompts installation.
* Launch the app from your phone's home screen.
* Tap **noVNC (6080)** or **RFB Native (5901)** for 1-tap instant connection!

### 2. Web Browser (noVNC)
Open Chrome/Firefox on your phone or PC (on same Wi-Fi) and go to:
```text
http://127.0.0.1:6080/vnc.html?autoconnect=true&password=vnc123
```
*(Default VNC Password: `vnc123`)*

---

## 🔧 Rebuilding the App APK in Termux

If you want to modify or compile the Android APK on your phone:

```bash
cd ~/termux-vnc-hybrid/vnc_apk_project
./build_apk.sh
```
This will compile, align, sign, and export a fresh APK to `/sdcard/Download/vnc-hybrid-client.apk`.
