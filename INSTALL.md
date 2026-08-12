# 📥 How to Download & Run VNC in Termux

A complete guide to downloading, installing, and connecting to the **Termux VNC Desktop & Hybrid Client App**.

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

## 🎮 Termux Terminal Commands

After installation, control your VNC server anytime with these commands:

| Command | Action |
| :--- | :--- |
| `vnc` or `vnc start` | Starts TigerVNC server (`5901`) & noVNC web proxy (`6080`) |
| `vnc status` | Displays current VNC running status & IP address |
| `vnc stop` | Stops VNC server and cleans up session locks |

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
