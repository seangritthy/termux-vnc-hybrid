#!/data/data/com.termux/files/usr/bin/env bash

set -e

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

export PATH="$BIN_DIR:$PATH"

install_packages() {
    if command -v pkg >/dev/null 2>&1; then
        echo "[+] Upgrading Termux packages to resolve library conflicts..."
        pkg upgrade -y -o Dpkg::Options::="--force-confnew" 2>/dev/null || true
        echo "[+] Enabling Termux X11 repository..."
        pkg install -y x11-repo 2>/dev/null || true
        pkg update -y || true
        pkg install -y "$@"
    elif command -v apt-get >/dev/null 2>&1; then
        if grep -q "termux" /etc/apt/sources.list 2>/dev/null || [ -d "/data/data/com.termux" ]; then
            apt-get update -y || true
            apt-get full-upgrade -y 2>/dev/null || true
            apt-get install -y x11-repo 2>/dev/null || true
        fi
        apt-get update -y || true
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

echo "======================================================="
echo "   🚀 TERMUX VNC & BROWSER AUTOMATIC SYSTEM UPDATER   "
echo "======================================================="

# 1. Update package lists & installed packages
echo "[+] Installing essential base packages..."
install_packages git curl wget net-tools || true

echo "[+] Installing VNC desktop & XFCE4 environment..."
install_packages tigervnc xfce4 xfce4-terminal dbus || \
install_packages tigervnc-standalone-server tigervnc-common xfce4 xfce4-terminal dbus || true

echo "[+] Installing Web Browsers & PRoot Distro..."
install_packages netsurf-gtk proot-distro || install_packages netsurf proot-distro || install_packages chromium proot-distro || true

# Setup PRoot Debian Linux & CLI shortcut
if command -v proot-distro >/dev/null 2>&1; then
    if ! proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
        echo "[+] Installing Debian Linux distribution via proot-distro..."
        proot-distro install debian || true
    fi

    if proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
        echo "[+] Installing Debian XFCE4 Desktop, Terminal & Firefox ESR inside Debian..."
        proot-distro login debian -- bash -c "
            apt-get update -y && \
            apt-get install -y xfce4 xfce4-terminal dbus-x11 firefox-esr desktop-base || true
        " 2>/dev/null || true
    fi

    # Create 'debian' CLI command shortcut
    for bdir in "$BIN_DIR" "/data/data/com.termux/files/usr/bin" "/usr/local/bin" "$HOME/bin" "$HOME/.local/bin"; do
        if [ -d "$bdir" ] || [ -d "$(dirname "$bdir")" ]; then
            mkdir -p "$bdir" 2>/dev/null || true
            cat << 'EOF' > "$bdir/debian"
#!/usr/bin/env bash
exec proot-distro login debian "$@"
EOF
            chmod +x "$bdir/debian" 2>/dev/null || true
        fi
    done
fi

# 2. Update noVNC proxy repository
NOVNC_DIR="$HOME/.novnc"
if [ -d "$NOVNC_DIR/.git" ]; then
    echo "[+] Updating noVNC web proxy repository..."
    git -C "$NOVNC_DIR" pull --rebase || true
    if [ -d "$NOVNC_DIR/utils/websockify/.git" ]; then
        git -C "$NOVNC_DIR/utils/websockify" pull --rebase || true
    fi
fi

# 3. Update termux-vnc-hybrid repo if present
HYBRID_DIR="$HOME/termux-vnc-hybrid"
if [ -d "$HYBRID_DIR/.git" ]; then
    echo "[+] Updating termux-vnc-hybrid repository..."
    git -C "$HYBRID_DIR" pull --rebase || true
fi

# 4. Create / update vnc-browser helper launcher
echo "[+] Configuring VNC Internet Browser launcher in $BIN_DIR..."
mkdir -p "$BIN_DIR"

cat << 'EOF' > "$BIN_DIR/vnc-browser"
#!/usr/bin/env bash
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
    echo "No GUI browser found."
    exec chromium --no-sandbox --disable-gpu "$@"
fi
EOF
chmod +x "$BIN_DIR/vnc-browser"

# 5. Create Desktop icons for Web Browsers inside VNC
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

# 6. Sync current scripts to $HOME
cp -f "$HYBRID_DIR/vnc.sh" "$HOME/vnc.sh" 2>/dev/null || true
cp -f "$HYBRID_DIR/updater.sh" "$HOME/updater.sh" 2>/dev/null || true
chmod +x "$HOME/vnc.sh" "$HOME/updater.sh" 2>/dev/null || true

# 7. Check Internet Connectivity
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

