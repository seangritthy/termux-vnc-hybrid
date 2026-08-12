#!/usr/bin/env bash
set -e

echo "======================================================="
echo "   🚀 TERMUX VNC & HYBRID CLIENT AUTOMATIC INSTALLER   "
echo "======================================================="

# Detect installation binary directory
if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ]; then
    BIN_DIR="$PREFIX/bin"
elif [ -d "/data/data/com.termux/files/usr/bin" ]; then
    BIN_DIR="/data/data/com.termux/files/usr/bin"
elif [ -w "/usr/local/bin" ]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
fi

# Package installer helper function
install_packages() {
    if command -v pkg >/dev/null 2>&1; then
        pkg update -y
        pkg install -y "$@"
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y "$@"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$@"
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm "$@"
    else
        echo "[!] No supported package manager found."
        return 1
    fi
}

# 1. Update and install required packages including Browsers
echo "[+] Installing required packages (TigerVNC, XFCE4, NetTools, Git, Curl)..."
install_packages tigervnc-standalone-server tigervnc-common xfce4 xfce4-terminal net-tools git wget curl netsurf-gtk chromium || \
install_packages tigervnc xfce4 xfce4-terminal net-tools git wget curl termux-tools netsurf chromium || true

# 2. Setup noVNC
NOVNC_DIR="$HOME/.novnc"
if [ ! -d "$NOVNC_DIR" ]; then
    echo "[+] Cloning noVNC web proxy into $NOVNC_DIR..."
    git clone --depth 1 https://github.com/novnc/noVNC.git "$NOVNC_DIR"
    git clone --depth 1 https://github.com/novnc/websockify "$NOVNC_DIR/utils/websockify"
fi

# 3. Setup VNC Password if not set
if [ ! -f "$HOME/.vnc/passwd" ]; then
    echo "[+] Setting default VNC password ('vnc123')..."
    mkdir -p "$HOME/.vnc"
    echo "vnc123" | vncpasswd -f > "$HOME/.vnc/passwd" 2>/dev/null || true
    chmod 600 "$HOME/.vnc/passwd" 2>/dev/null || true
fi

# 4. Copy vnc.sh & updater.sh scripts & create executable binaries
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -f "$SCRIPT_SRC/vnc.sh" "$HOME/vnc.sh"
cp -f "$SCRIPT_SRC/updater.sh" "$HOME/updater.sh" 2>/dev/null || true
chmod +x "$HOME/vnc.sh" "$HOME/updater.sh" 2>/dev/null || true

# Create global terminal command wrapper
echo "[+] Creating 'vnc' global terminal command in $BIN_DIR..."
mkdir -p "$BIN_DIR"
cat << 'EOF' > "$BIN_DIR/vnc"
#!/usr/bin/env bash
exec "$HOME/vnc.sh" "$@"
EOF
chmod +x "$BIN_DIR/vnc"

# 5. Copy & Install VNC Hybrid Client APK (if on Termux/Android)
APK_PATH="$SCRIPT_SRC/bin/vnc-hybrid-client.apk"
SDCARD_APK="/sdcard/Download/vnc-hybrid-client.apk"

if [ -f "$APK_PATH" ]; then
    echo "[+] Copying VNC Hybrid Client APK to Downloads ($SDCARD_APK)..."
    cp -f "$APK_PATH" "$SDCARD_APK" 2>/dev/null || cp -f "$APK_PATH" "/storage/emulated/0/Download/vnc-hybrid-client.apk" 2>/dev/null || true
    chmod 666 "$SDCARD_APK" 2>/dev/null || true
    if command -v termux-open >/dev/null 2>&1; then
        echo "[+] Triggering Android APK installation..."
        termux-open "$SDCARD_APK" 2>/dev/null || true
    fi
fi

# 6. Run updater script to set up browser desktop shortcuts and check internet
"$HOME/vnc.sh" update

# 7. Start VNC Server
echo "[+] Starting VNC Server..."
"$HOME/vnc.sh" start

echo ""
echo "======================================================="
echo " 🎉 INSTALLATION & INTERNET BROWSER SETUP COMPLETE!"
echo "======================================================="
echo " You can manage VNC anytime using:"
echo "   vnc          -> Start VNC Server"
echo "   vnc status   -> Check VNC Status"
echo "   vnc stop     -> Stop VNC Server"
echo "   vnc update   -> Update packages & VNC system"
echo ""
if [ -f "$SDCARD_APK" ]; then
    echo " Android App APK installed to: /sdcard/Download/vnc-hybrid-client.apk"
fi
echo " Web Access URL: http://127.0.0.1:6080/vnc.html?autoconnect=true&password=vnc123"
echo " Desktop Browsers: Double-click 'Web Browser' or 'Chromium' in VNC"
echo "======================================================="

