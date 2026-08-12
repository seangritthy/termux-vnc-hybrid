#!/data/data/com.termux/files/usr/bin/env bash

set -e

export PATH=/data/data/com.termux/files/usr/bin:$PATH

echo "======================================================="
echo "   🚀 TERMUX VNC & BROWSER AUTOMATIC SYSTEM UPDATER   "
echo "======================================================="

# 1. Update package lists & installed packages
echo "[+] Updating Termux package repositories..."
pkg update -y || apt-get update -y

echo "[+] Upgrading installed packages..."
pkg upgrade -y || apt-get upgrade -y

# 2. Ensure VNC and Browser packages are installed
echo "[+] Checking and installing VNC desktop & Web Browser dependencies..."
pkg install -y tigervnc xfce4 xfce4-terminal net-tools git wget curl termux-tools netsurf chromium || true

# 3. Update noVNC proxy repository
NOVNC_DIR="$HOME/.novnc"
if [ -d "$NOVNC_DIR/.git" ]; then
    echo "[+] Updating noVNC web proxy repository..."
    git -C "$NOVNC_DIR" pull --rebase || true
    if [ -d "$NOVNC_DIR/utils/websockify/.git" ]; then
        git -C "$NOVNC_DIR/utils/websockify" pull --rebase || true
    fi
fi

# 4. Update termux-vnc-hybrid repo if present
HYBRID_DIR="$HOME/termux-vnc-hybrid"
if [ -d "$HYBRID_DIR/.git" ]; then
    echo "[+] Updating termux-vnc-hybrid repository..."
    git -C "$HYBRID_DIR" pull --rebase || true
fi

# 5. Create / update vnc-browser helper launcher
echo "[+] Configuring VNC Internet Browser launcher..."
mkdir -p "$HOME/bin"
mkdir -p /data/data/com.termux/files/usr/bin

cat << 'EOF' > /data/data/com.termux/files/usr/bin/vnc-browser
#!/data/data/com.termux/files/usr/bin/env bash
export DISPLAY="${DISPLAY:-:1}"
export LIBGL_ALWAYS_SOFTWARE=1

# Check for available browsers in order of preference
if command -v chromium >/dev/null 2>&1; then
    exec chromium --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer "$@"
elif command -v netsurf-gtk3 >/dev/null 2>&1; then
    exec netsurf-gtk3 "$@"
elif command -v netsurf >/dev/null 2>&1; then
    exec netsurf "$@"
elif command -v firefox >/dev/null 2>&1; then
    exec firefox "$@"
else
    echo "No GUI browser found. Installing Chromium & NetSurf..."
    pkg install -y chromium netsurf
    exec chromium --no-sandbox --disable-gpu "$@"
fi
EOF
chmod +x /data/data/com.termux/files/usr/bin/vnc-browser

# 6. Create Desktop icons for Web Browsers inside VNC
echo "[+] Updating Desktop shortcuts for VNC..."
DESKTOP_DIR="$HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

# Chromium Desktop File
cat << 'EOF' > "$DESKTOP_DIR/chromium.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Chromium Web Browser
Comment=Access the Internet inside VNC Desktop
Exec=vnc-browser %u
Icon=chromium
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF
chmod +x "$DESKTOP_DIR/chromium.desktop"

# NetSurf Desktop File
cat << 'EOF' > "$DESKTOP_DIR/netsurf.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=NetSurf Web Browser
Comment=Lightweight Fast Internet Browser for VNC
Exec=netsurf-gtk3 %u
Icon=netsurf
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF
chmod +x "$DESKTOP_DIR/netsurf.desktop"

# Internet Browser Main Desktop File
cat << 'EOF' > "$DESKTOP_DIR/vnc-browser.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Web Browser (Internet)
Comment=Launch default Internet Browser
Exec=vnc-browser %u
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF
chmod +x "$DESKTOP_DIR/vnc-browser.desktop"

# Copy desktop shortcuts to application menu directory
mkdir -p "$HOME/.local/share/applications"
cp -f "$DESKTOP_DIR"/*.desktop "$HOME/.local/share/applications/" 2>/dev/null || true

# 7. Sync current scripts to $HOME
cp -f "$HYBRID_DIR/vnc.sh" "$HOME/vnc.sh" 2>/dev/null || true
cp -f "$HYBRID_DIR/updater.sh" "$HOME/updater.sh" 2>/dev/null || true
chmod +x "$HOME/vnc.sh" "$HOME/updater.sh" 2>/dev/null || true

# 8. Check Internet Connectivity
echo "[+] Testing Internet Connectivity..."
if curl -s -I --connect-timeout 5 https://www.google.com >/dev/null 2>&1 || ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    NET_STATUS="Connected (Online)"
else
    NET_STATUS="Offline (Check phone network/Wi-Fi connection)"
fi

echo ""
echo "======================================================="
echo " 🎉 UPDATE COMPLETE & INTERNET BROWSING IS READY!"
echo "======================================================="
echo " Internet Status: $NET_STATUS"
echo " Web Browsers:    Chromium & NetSurf"
echo ""
echo " How to Browse Internet in VNC:"
echo " 1. Open VNC desktop (via VNC app or noVNC browser)."
echo " 2. Double-click 'Web Browser' or 'Chromium' on Desktop."
echo " 3. Or launch 'vnc-browser' from terminal inside VNC."
echo "======================================================="
