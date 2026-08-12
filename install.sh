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
        echo "[+] Upgrading Termux packages to resolve OpenSSL/libngtcp2 library conflicts..."
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

# 1. Update and install required packages in stages
echo "[+] Upgrading and installing essential base packages (git, curl, wget, net-tools)..."
install_packages git curl wget net-tools || true

echo "[+] Installing VNC & XFCE4 Desktop Environment..."
install_packages tigervnc xfce4 xfce4-terminal || \
install_packages tigervnc-standalone-server tigervnc-common xfce4 xfce4-terminal || true

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

# 2. Setup noVNC
NOVNC_DIR="$HOME/.novnc"
if [ ! -d "$NOVNC_DIR" ]; then
    echo "[+] Setting up noVNC web proxy in $NOVNC_DIR..."
    git clone --depth 1 https://github.com/novnc/noVNC.git "$NOVNC_DIR" 2>/dev/null || \
    (mkdir -p "$NOVNC_DIR" && wget -qO- https://github.com/novnc/noVNC/archive/refs/heads/master.tar.gz | tar -xz -C "$NOVNC_DIR" --strip-components=1) || true

    mkdir -p "$NOVNC_DIR/utils/websockify"
    git clone --depth 1 https://github.com/novnc/websockify "$NOVNC_DIR/utils/websockify" 2>/dev/null || \
    (wget -qO- https://github.com/novnc/websockify/archive/refs/heads/master.tar.gz | tar -xz -C "$NOVNC_DIR/utils/websockify" --strip-components=1) || true
fi

# 3. Setup VNC Password if not set
if [ ! -f "$HOME/.vnc/passwd" ]; then
    echo "[+] Setting default VNC password ('vnc123')..."
    mkdir -p "$HOME/.vnc"
    echo "vnc123" | vncpasswd -f > "$HOME/.vnc/passwd" 2>/dev/null || true
    chmod 600 "$HOME/.vnc/passwd" 2>/dev/null || true
fi

# 4. Copy or download vnc.sh & updater.sh scripts & create executable binaries
GITHUB_RAW="https://raw.githubusercontent.com/seangritthy/termux-vnc-hybrid/main"
SCRIPT_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "$HOME")"

if [ -f "$SCRIPT_SRC/vnc.sh" ]; then
    cp -f "$SCRIPT_SRC/vnc.sh" "$HOME/vnc.sh"
else
    echo "[+] Downloading vnc.sh script from GitHub..."
    curl -sSL "$GITHUB_RAW/vnc.sh" -o "$HOME/vnc.sh" 2>/dev/null || wget -qO "$HOME/vnc.sh" "$GITHUB_RAW/vnc.sh" || true
fi

if [ -f "$SCRIPT_SRC/updater.sh" ]; then
    cp -f "$SCRIPT_SRC/updater.sh" "$HOME/updater.sh"
else
    echo "[+] Downloading updater.sh script from GitHub..."
    curl -sSL "$GITHUB_RAW/updater.sh" -o "$HOME/updater.sh" 2>/dev/null || wget -qO "$HOME/updater.sh" "$GITHUB_RAW/updater.sh" || true
fi

chmod +x "$HOME/vnc.sh" "$HOME/updater.sh" 2>/dev/null || true

# Create global terminal command wrapper in all candidate PATH directories
echo "[+] Creating 'vnc' global terminal command..."
WRAPPER_SCRIPT='#!/usr/bin/env bash
exec "$HOME/vnc.sh" "$@"
'

for bdir in "$BIN_DIR" "/data/data/com.termux/files/usr/bin" "/usr/local/bin" "$HOME/bin" "$HOME/.local/bin"; do
    if [ -d "$bdir" ] || [ -d "$(dirname "$bdir")" ]; then
        mkdir -p "$bdir" 2>/dev/null || true
        echo "$WRAPPER_SCRIPT" > "$bdir/vnc" 2>/dev/null || true
        chmod +x "$bdir/vnc" 2>/dev/null || true
    fi
done

# 5. Copy & Install VNC Hybrid Client APK (if on Termux/Android)
APK_PATH="$SCRIPT_SRC/bin/vnc-hybrid-client.apk"
SDCARD_APK="/sdcard/Download/vnc-hybrid-client.apk"
EMULATED_APK="/storage/emulated/0/Download/vnc-hybrid-client.apk"

if [ ! -f "$APK_PATH" ]; then
    TMP_APK="/tmp/vnc-hybrid-client.apk"
    echo "[+] Fetching VNC Hybrid Client APK from GitHub..."
    curl -sSL "$GITHUB_RAW/bin/vnc-hybrid-client.apk" -o "$TMP_APK" 2>/dev/null || true
    [ -f "$TMP_APK" ] && APK_PATH="$TMP_APK"
fi

if [ -f "$APK_PATH" ]; then
    echo "[+] Copying VNC Hybrid Client APK to Downloads ($SDCARD_APK)..."
    cp -f "$APK_PATH" "$SDCARD_APK" 2>/dev/null || cp -f "$APK_PATH" "$EMULATED_APK" 2>/dev/null || true
    chmod 666 "$SDCARD_APK" 2>/dev/null || true
    if command -v termux-open >/dev/null 2>&1; then
        echo "[+] Triggering Android APK installation..."
        termux-open "$SDCARD_APK" 2>/dev/null || termux-open "$EMULATED_APK" 2>/dev/null || true
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

