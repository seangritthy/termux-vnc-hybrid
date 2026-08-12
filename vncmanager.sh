#!/data/data/com.termux/files/usr/bin/env bash

VNC_PORT=5901
NOVNC_PORT=6080
DISPLAY_NUM=":1"
NOVNC_DIR="$HOME/.novnc"

clean_locks() {
    vncserver -kill "$DISPLAY_NUM" >/dev/null 2>&1 || true
    pkill -9 -f "Xvnc" >/dev/null 2>&1 || true
    pkill -9 -f "novnc_proxy" >/dev/null 2>&1 || true
    pkill -9 -f "websockify" >/dev/null 2>&1 || true
    rm -rf /data/data/com.termux/files/usr/tmp/.X*-lock 2>/dev/null || true
    rm -rf /data/data/com.termux/files/usr/tmp/.X11-unix/X* 2>/dev/null || true
    rm -rf "$HOME/.vnc/*.pid" 2>/dev/null || true
    rm -rf "$HOME/.vnc/*.log" 2>/dev/null || true
}

start_vnc() {
    echo "=== Starting VNC Server & Desktop Environment ==="
    
    chmod +x "$HOME/.vnc/xstartup" 2>/dev/null || true

    if [ ! -f "$HOME/.vnc/passwd" ]; then
        echo "Creating default VNC password ('vnc123')..."
        mkdir -p "$HOME/.vnc"
        echo "vnc123" | vncpasswd -f > "$HOME/.vnc/passwd" 2>/dev/null
        chmod 600 "$HOME/.vnc/passwd"
    fi

    clean_locks
    sleep 1

    echo "Starting VNC server on display $DISPLAY_NUM (Port $VNC_PORT)..."
    setsid nohup vncserver "$DISPLAY_NUM" -geometry 1280x720 -depth 24 </dev/null >/dev/null 2>&1 &
    sleep 3

    if [ -d "$NOVNC_DIR" ]; then
        echo "Starting noVNC Web Proxy on port $NOVNC_PORT..."
        setsid nohup "$NOVNC_DIR/utils/novnc_proxy" --vnc 127.0.0.1:$VNC_PORT --listen $NOVNC_PORT </dev/null > "$HOME/.novnc.log" 2>&1 &
        sleep 2
    fi

    echo ""
    echo "======================================================="
    echo "  VNC SERVER & DESKTOP ARE READY!"
    echo "======================================================="
    echo " 1. Native RFB (Port 5901): 127.0.0.1:5901 (pass: vnc123)"
    echo " 2. noVNC Web (Port 6080):  http://127.0.0.1:6080/vnc.html"
    echo "======================================================="
}

stop_vnc() {
    echo "=== Stopping VNC Server & noVNC ==="
    clean_locks
    echo "VNC services stopped."
}

status_vnc() {
    echo "=== VNC Server Status ==="
    if pgrep -f "Xvnc" >/dev/null 2>&1; then
        echo "[+] VNC Server (Xvnc) is RUNNING on Port $VNC_PORT"
    else
        echo "[-] VNC Server is NOT running."
    fi

    if pgrep -f "websockify" >/dev/null 2>&1 || pgrep -f "novnc_proxy" >/dev/null 2>&1; then
        echo "[+] noVNC Web Proxy is RUNNING on Port $NOVNC_PORT"
    else
        echo "[-] noVNC Web Proxy is NOT running."
    fi
}

case "$1" in
    start)
        start_vnc
        ;;
    stop)
        stop_vnc
        ;;
    status)
        status_vnc
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        ;;
esac
