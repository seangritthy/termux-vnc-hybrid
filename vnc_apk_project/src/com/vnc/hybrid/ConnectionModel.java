package com.vnc.hybrid;

public class ConnectionModel {
    public String host;
    public int port;
    public String password;
    public boolean isWebMode;

    public ConnectionModel(String host, int port, String password, boolean isWebMode) {
        this.host = host != null && !host.trim().isEmpty() ? host.trim() : "127.0.0.1";
        this.port = port > 0 ? port : (isWebMode ? 6080 : 5901);
        this.password = password != null ? password : "";
        this.isWebMode = isWebMode;
    }
}
