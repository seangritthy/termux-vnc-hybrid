#!/data/data/com.termux/files/usr/bin/env bash

VNC_PORT=5901
NOVNC_PORT=6080
DISPLAY_NUM=":1"
NOVNC_DIR="$HOME/.novnc"

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

get_ip() {
    local ip=""
    if command -v ip >/dev/null 2>&1; then
        ip=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' | head -n 1)
    fi
    if [ -z "$ip" ] && command -v hostname >/dev/null 2>&1; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [ -z "$ip" ] && command -v ifconfig >/dev/null 2>&1; then
        ip=$(ifconfig 2>/dev/null | awk '/wlan0/{flag=1} flag && /inet/{print $2; flag=0}')
        [ -z "$ip" ] && ip=$(ifconfig 2>/dev/null | grep -E 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
    fi
    if [ -z "$ip" ]; then
        ip="<YOUR_SERVER_IP>"
    fi
    echo "$ip"
}

clean_locks() {
    vncserver -kill "$DISPLAY_NUM" >/dev/null 2>&1 || true
    pkill -9 -f "Xvnc" >/dev/null 2>&1 || true
    pkill -9 -f "novnc_proxy" >/dev/null 2>&1 || true
    pkill -9 -f "websockify" >/dev/null 2>&1 || true

    local tmp_dirs=("/tmp" "/data/data/com.termux/files/usr/tmp")
    [ -n "$TMPDIR" ] && tmp_dirs+=("$TMPDIR")
    [ -n "$PREFIX" ] && tmp_dirs+=("$PREFIX/tmp")

    for dir in "${tmp_dirs[@]}"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"/.X*-lock 2>/dev/null || true
            rm -rf "$dir"/.X11-unix/X* 2>/dev/null || true
        fi
    done
    rm -rf "$HOME/.vnc/*.pid" 2>/dev/null || true
    rm -rf "$HOME/.vnc/*.log" 2>/dev/null || true
}

ensure_browser_setup() {
    mkdir -p "$BIN_DIR"
    
    # Create vnc-browser helper
    cat << 'EOF' > "$BIN_DIR/vnc-browser"
#!/usr/bin/env bash
export DISPLAY="${DISPLAY:-:1}"
export LIBGL_ALWAYS_SOFTWARE=1

if command -v proot-distro >/dev/null 2>&1 && proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
    exec proot-distro login debian --shared-tmp -- env DISPLAY="${DISPLAY:-:1}" XAUTHORITY=/root/.Xauthority firefox-esr "$@"
elif command -v chromium >/dev/null 2>&1; then
    exec chromium --no-sandbox --disable-gpu --disable-dev-shm-usage --disable-software-rasterizer "$@"
elif command -v netsurf-gtk3 >/dev/null 2>&1; then
    exec netsurf-gtk3 "$@"
elif command -v firefox >/dev/null 2>&1; then
    exec firefox "$@"
else
    exec proot-distro login debian --shared-tmp -- env DISPLAY="${DISPLAY:-:1}" XAUTHORITY=/root/.Xauthority firefox-esr "$@"
fi
EOF
    chmod +x "$BIN_DIR/vnc-browser"

    # Create vnc-debian-terminal helper
    cat << 'EOF' > "$BIN_DIR/vnc-debian-terminal"
#!/usr/bin/env bash
export DISPLAY="${DISPLAY:-:1}"
if command -v proot-distro >/dev/null 2>&1 && proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
    exec proot-distro login debian --shared-tmp -- env DISPLAY="${DISPLAY:-:1}" XAUTHORITY=/root/.Xauthority xfce4-terminal "$@"
else
    exec xfce4-terminal "$@"
fi
EOF
    chmod +x "$BIN_DIR/vnc-debian-terminal"

    # Create 'debian' CLI shortcut wrapper across candidate bin paths
    if command -v proot-distro >/dev/null 2>&1 && proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
        for bdir in "$BIN_DIR" "/data/data/com.termux/files/usr/bin" "/usr/local/bin" "$HOME/bin" "$HOME/.local/bin"; do
            if [ -d "$bdir" ] || [ -d "$(dirname "$bdir")" ]; then
                mkdir -p "$bdir" 2>/dev/null || true
                cat << 'EOC' > "$bdir/debian"
#!/usr/bin/env bash
exec proot-distro login debian "$@"
EOC
                chmod +x "$bdir/debian" 2>/dev/null || true
            fi
        done

        # Also create desktop icons inside proot Debian /root/Desktop
        proot-distro login debian -- bash -c "mkdir -p /root/Desktop && cat << 'EOF' > /root/Desktop/debian-terminal.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Debian Terminal
Comment=Open Debian Linux Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF
chmod +x /root/Desktop/debian-terminal.desktop

cat << 'EOF' > /root/Desktop/firefox.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox Web Browser (Debian)
Comment=Browse the Web using Firefox ESR in Debian
Exec=firefox-esr %u
Icon=firefox-esr
Terminal=false
Categories=Network;WebBrowser;
EOF
chmod +x /root/Desktop/firefox.desktop
" 2>/dev/null || true
    fi

    # Create shortcuts on Termux VNC Desktop ($HOME/Desktop)
    local DESKTOP_DIR="$HOME/Desktop"
    mkdir -p "$DESKTOP_DIR"

    cat << 'EOF' > "$DESKTOP_DIR/debian-terminal.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Debian Terminal
Comment=Open Debian Root Terminal inside VNC
Exec=vnc-debian-terminal
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
StartupNotify=true
EOF
    chmod +x "$DESKTOP_DIR/debian-terminal.desktop"

    cat << 'EOF' > "$DESKTOP_DIR/vnc-browser.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Web Browser (Firefox / Internet)
Comment=Launch Firefox / Web Browser inside VNC
Exec=vnc-browser %u
Icon=web-browser
Terminal=false
Categories=Network;WebBrowser;
StartupNotify=true
EOF
    chmod +x "$DESKTOP_DIR/vnc-browser.desktop"
}

ensure_xstartup() {
    mkdir -p "$HOME/.vnc"
    cat << 'EOF' > "$HOME/.vnc/xstartup"
#!/usr/bin/env bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS

[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources 2>/dev/null || true
xsetroot -solid "#121318" 2>/dev/null || true

# Disable X11 screen saver and DPMS power saving
xset s off 2>/dev/null || true
xset -dpms 2>/dev/null || true
xset s noblank 2>/dev/null || true

# Start XFCE4 Desktop Session natively for instant display setup
if command -v startxfce4 >/dev/null 2>&1; then
    if command -v dbus-launch >/dev/null 2>&1; then
        dbus-launch --exit-with-session startxfce4 &
    else
        startxfce4 &
    fi
elif command -v xfce4-session >/dev/null 2>&1; then
    xfce4-session &
else
    xterm &
fi

# Auto-launch Debian Linux Terminal on Desktop startup if Debian is installed
if command -v proot-distro >/dev/null 2>&1 && proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
    (sleep 2 && proot-distro login debian --shared-tmp -- env DISPLAY="${DISPLAY:-:1}" XAUTHORITY=/root/.Xauthority xfce4-terminal) &
fi
EOF
    chmod +x "$HOME/.vnc/xstartup"
}

start_vnc() {
    echo "======================================================="
    echo "       STARTING VNC SERVER & DEBIAN DESKTOP (PROOT)    "
    echo "======================================================="

    ensure_xstartup
    chmod +x "$HOME/.vnc/xstartup" 2>/dev/null || true
    ensure_browser_setup

    if command -v termux-wake-lock >/dev/null 2>&1; then
        termux-wake-lock 2>/dev/null || true
        echo "[+] Termux wake lock acquired (prevents Android CPU sleep)."
    fi

    if [ ! -f "$HOME/.vnc/passwd" ]; then
        echo "[+] Setting default VNC password ('vnc123')..."
        mkdir -p "$HOME/.vnc"
        echo "vnc123" | vncpasswd -f > "$HOME/.vnc/passwd" 2>/dev/null
        chmod 600 "$HOME/.vnc/passwd"
    fi

    echo "[+] Cleaning previous locks & server instances..."
    clean_locks
    sleep 1

    echo "[+] Starting TigerVNC server on display $DISPLAY_NUM (Port $VNC_PORT, listening on all IPs)..."
    setsid nohup vncserver "$DISPLAY_NUM" -geometry 1280x720 -depth 24 -localhost no -IdleTimeout 0 -MaxIdleTime 0 </dev/null >/dev/null 2>&1 &
    sleep 3

    if [ -d "$NOVNC_DIR" ]; then
        command -v termux-fix-shebang >/dev/null 2>&1 && termux-fix-shebang "$NOVNC_DIR/utils/novnc_proxy" "$NOVNC_DIR/utils/websockify/run" 2>/dev/null || true
        echo "[+] Starting noVNC Web Proxy on Port $NOVNC_PORT (listening on 0.0.0.0)..."
        setsid nohup "$NOVNC_DIR/utils/novnc_proxy" --vnc 127.0.0.1:$VNC_PORT --listen 0.0.0.0:$NOVNC_PORT --heartbeat 30 </dev/null > "$HOME/.novnc.log" 2>&1 &
        sleep 2
    fi

    IP_ADDR=$(get_ip)

    echo ""
    echo "======================================================="
    echo "   VNC IS READY (PROOT DEBIAN DESKTOP + TERMINAL)!     "
    echo "======================================================="
    echo " 1. FOR OTHER PHONES / COMPUTERS ON SAME WI-FI:"
    echo "    - Web Browser Access (noVNC):"
    echo "      http://$IP_ADDR:$NOVNC_PORT/vnc.html?autoconnect=true&password=vnc123"
    echo ""
    echo "    - VNC Viewer App (AVNC / RealVNC / bVNC):"
    echo "      Address:  $IP_ADDR:$VNC_PORT"
    echo "      Password: vnc123"
    echo "-------------------------------------------------------"
    echo " 2. FOR THIS PHONE (LOCAL):"
    echo "    - Web Browser: http://127.0.0.1:$NOVNC_PORT/vnc.html?autoconnect=true&password=vnc123"
    echo "    - VNC App:     127.0.0.1:$VNC_PORT"
    echo "-------------------------------------------------------"
    echo " 3. DEBIAN SYSTEM & TERMINAL ACCESS:"
    echo "    - VNC Desktop Environment: Debian XFCE4 Desktop"
    echo "    - Terminal in VNC Desktop: Debian Terminal (xfce4-terminal)"
    echo "    - CLI Access in Termux:    type 'debian'"
    echo "======================================================="
}

stop_vnc() {
    echo "=== Stopping VNC Server & noVNC Web Proxy ==="
    clean_locks
    echo "[+] VNC services stopped."
}

status_vnc() {
    IP_ADDR=$(get_ip)
    echo "=== VNC Server Status ==="
    if pgrep -f "Xvnc" >/dev/null 2>&1; then
        echo "[+] VNC Server (Xvnc) is RUNNING on Port $VNC_PORT"
        echo "    Other Phone VNC Address: $IP_ADDR:$VNC_PORT"
    else
        echo "[-] VNC Server is NOT running."
    fi

    if pgrep -f "websockify" >/dev/null 2>&1 || pgrep -f "novnc_proxy" >/dev/null 2>&1; then
        echo "[+] noVNC Web Proxy is RUNNING on Port $NOVNC_PORT"
        echo "    Other Phone Web URL: http://$IP_ADDR:$NOVNC_PORT/vnc.html"
    else
        echo "[-] noVNC Web Proxy is NOT running."
    fi

    if command -v proot-distro >/dev/null 2>&1 && proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
        echo "[+] Proot-Distro Debian: INSTALLED & Active for VNC Desktop"
    fi
}

install_debian_distro() {
    echo "======================================================="
    echo "       INSTALLING PROOT DEBIAN LINUX DISTRO            "
    echo "======================================================="
    
    if command -v pkg >/dev/null 2>&1; then
        pkg update -y || true
        pkg install -y proot-distro || true
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update -y || true
        apt-get install -y proot-distro || true
    fi

    if command -v proot-distro >/dev/null 2>&1; then
        if ! proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
            echo "[+] Downloading & Installing Debian Linux (this may take 1-3 minutes)..."
            proot-distro install debian
        else
            echo "[+] Debian Linux is already installed!"
        fi

        echo "[+] Setting up XFCE4 Desktop, Terminal & Firefox inside Debian..."
        proot-distro login debian -- bash -c "
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -y && \
            apt-get install -y xfce4 xfce4-terminal dbus-x11 firefox-esr desktop-base || true
        "

        # Create 'debian' CLI shortcut wrapper across candidate bin paths
        for bdir in "$BIN_DIR" "/data/data/com.termux/files/usr/bin" "/usr/local/bin" "$HOME/bin" "$HOME/.local/bin"; do
            if [ -d "$bdir" ] || [ -d "$(dirname "$bdir")" ]; then
                mkdir -p "$bdir" 2>/dev/null || true
                cat << 'EOC' > "$bdir/debian"
#!/usr/bin/env bash
exec proot-distro login debian "$@"
EOC
                chmod +x "$bdir/debian" 2>/dev/null || true
            fi
        done
        echo "======================================================="
        echo " 🎉 DEBIAN LINUX INSTALLATION COMPLETE!"
        echo "======================================================="
        echo " You can now start VNC with Debian Desktop by typing:"
        echo "   vnc start"
        echo "======================================================="
    else
        echo "[!] proot-distro is not supported on this platform."
    fi
}

update_vnc() {
    if [ -f "$HOME/updater.sh" ]; then
        bash "$HOME/updater.sh"
    elif [ -f "$HOME/termux-vnc-hybrid/updater.sh" ]; then
        bash "$HOME/termux-vnc-hybrid/updater.sh"
    else
        echo "[-] updater.sh not found."
    fi
}

case "$1" in
    start)
        if command -v proot-distro >/dev/null 2>&1 && ! proot-distro list 2>/dev/null | grep -q "debian (installed)"; then
            echo "[!] PRoot Debian is not installed yet. Installing Debian now..."
            install_debian_distro
        fi
        start_vnc
        ;;
    stop)
        stop_vnc
        ;;
    status)
        status_vnc
        ;;
    debian-install|setup-debian|install-debian)
        install_debian_distro
        ;;
    update|updater)
        update_vnc
        ;;
    *)
        start_vnc
        ;;
esac

