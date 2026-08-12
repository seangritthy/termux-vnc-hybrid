#!/data/data/com.termux/files/usr/bin/env bash

VNC_PORT=5901
NOVNC_PORT=6080
DISPLAY_NUM=":1"
NOVNC_DIR="$HOME/.novnc"

get_ip() {
    local wifi_ip=$(ifconfig 2>/dev/null | awk '/wlan0/{flag=1} flag && /inet/{print $2; flag=0}')
    if [ -n "$wifi_ip" ]; then
        echo "$wifi_ip"
    else
        local ip=$(ifconfig 2>/dev/null | grep -E 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
        if [ -z "$ip" ]; then
            ip="<YOUR_PHONE_IP>"
        fi
        echo "$ip"
    fi
}

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
    echo "======================================================="
    echo "       STARTING VNC SERVER & DESKTOP (MULTI-DEVICE)    "
    echo "======================================================="

    chmod +x "$HOME/.vnc/xstartup" 2>/dev/null || true

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
    setsid nohup vncserver "$DISPLAY_NUM" -geometry 1280x720 -depth 24 -localhost no </dev/null >/dev/null 2>&1 &
    sleep 3

    if [ -d "$NOVNC_DIR" ]; then
        echo "[+] Starting noVNC Web Proxy on Port $NOVNC_PORT (listening on 0.0.0.0)..."
        setsid nohup "$NOVNC_DIR/utils/novnc_proxy" --vnc 127.0.0.1:$VNC_PORT --listen 0.0.0.0:$NOVNC_PORT </dev/null > "$HOME/.novnc.log" 2>&1 &
        sleep 2
    fi

    IP_ADDR=$(get_ip)

    echo ""
    echo "======================================================="
    echo "     VNC IS READY FOR THIS PHONE & OTHER PHONES!       "
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
        start_vnc
        ;;
esac
