#!/data/data/com.termux/files/usr/bin/env bash
set -e

echo "======================================================="
echo "   🚀 TERMUX VNC & HYBRID CLIENT AUTOMATIC INSTALLER   "
echo "======================================================="

# 1. Update and install required packages including Browsers
echo "[+] Installing required packages (TigerVNC, XFCE4, NetSurf, Chromium, Net-Tools, Git)..."
pkg update -y
pkg install -y tigervnc xfce4 xfce4-terminal net-tools git wget curl termux-tools netsurf chromium

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
    echo "vnc123" | vncpasswd -f > "$HOME/.vnc/passwd"
    chmod 600 "$HOME/.vnc/passwd"
fi

# 4. Copy vnc.sh & updater.sh scripts & create executable binaries
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp -f "$SCRIPT_SRC/vnc.sh" "$HOME/vnc.sh"
cp -f "$SCRIPT_SRC/updater.sh" "$HOME/updater.sh" 2>/dev/null || true
chmod +x "$HOME/vnc.sh" "$HOME/updater.sh" 2>/dev/null || true

# Create /data/data/com.termux/files/usr/bin/vnc command wrapper
echo "[+] Creating 'vnc' global terminal command..."
cat << 'EOF' > /data/data/com.termux/files/usr/bin/vnc
#!/data/data/com.termux/files/usr/bin/env bash
exec "$HOME/vnc.sh" "$@"
EOF
chmod +x /data/data/com.termux/files/usr/bin/vnc

# 5. Copy & Install VNC Hybrid Client APK
APK_PATH="$SCRIPT_SRC/bin/vnc-hybrid-client.apk"
SDCARD_APK="/sdcard/Download/vnc-hybrid-client.apk"

if [ -f "$APK_PATH" ]; then
    echo "[+] Copying VNC Hybrid Client APK to Downloads ($SDCARD_APK)..."
    cp -f "$APK_PATH" "$SDCARD_APK" 2>/dev/null || cp -f "$APK_PATH" "/storage/emulated/0/Download/vnc-hybrid-client.apk" 2>/dev/null || true
    chmod 666 "$SDCARD_APK" 2>/dev/null || true
    echo "[+] Triggering Android APK installation..."
    termux-open "$SDCARD_APK" 2>/dev/null || true
fi

# 6. Run updater script to set up browser desktop shortcuts and check internet
"$HOME/vnc.sh" update

# 7. Start VNC Server
echo "[+] Starting VNC Server..."
"$HOME/vnc.sh" start

echo ""
echo "======================================================="
echo " 🎉 INSTALLATION & INTERNET BROUSER SETUP COMPLETE!"
echo "======================================================="
echo " You can manage VNC anytime using:"
echo "   vnc          -> Start VNC Server"
echo "   vnc status   -> Check VNC Status"
echo "   vnc stop     -> Stop VNC Server"
echo "   vnc update   -> Update packages & VNC system"
echo ""
echo " Android App APK installed to: /sdcard/Download/vnc-hybrid-client.apk"
echo " Web Access URL: http://127.0.0.1:6080/vnc.html?autoconnect=true&password=vnc123"
echo " Desktop Browsers: Double-click 'Web Browser' or 'Chromium' in VNC"
echo "======================================================="
