package com.vnc.hybrid;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import java.net.InetSocketAddress;
import java.net.Socket;

public class MainActivity extends Activity {

    private TextView tvLocalStatus;
    private EditText etHost, etPort, etPassword;

    private boolean isRfbActive = false;
    private boolean isWebActive = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        tvLocalStatus = findViewById(R.id.tv_local_status);
        etHost = findViewById(R.id.et_host);
        etPort = findViewById(R.id.et_port);
        etPassword = findViewById(R.id.et_password);

        Button btnQuickNoVnc = findViewById(R.id.btn_quick_novnc);
        Button btnQuickRfb = findViewById(R.id.btn_quick_rfb);
        Button btnCustomNoVnc = findViewById(R.id.btn_custom_novnc);
        Button btnCustomRfb = findViewById(R.id.btn_custom_rfb);

        // Load saved connection details
        etHost.setText(StorageHelper.getSavedHost(this));
        etPort.setText(String.valueOf(StorageHelper.getSavedPort(this, true)));
        etPassword.setText(StorageHelper.getSavedPassword(this));

        checkLocalServices();

        btnQuickNoVnc.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchVnc("127.0.0.1", 6080, getPass(), true);
            }
        });

        btnQuickRfb.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                launchVnc("127.0.0.1", 5901, getPass(), false);
            }
        });

        btnCustomNoVnc.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String host = etHost.getText().toString().trim();
                int port = parsePort(etPort.getText().toString(), 6080);
                String pass = getPass();
                StorageHelper.saveLastConnection(MainActivity.this, host, port, pass);
                launchVnc(host, port, pass, true);
            }
        });

        btnCustomRfb.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String host = etHost.getText().toString().trim();
                int port = parsePort(etPort.getText().toString(), 5901);
                String pass = getPass();
                StorageHelper.saveLastConnection(MainActivity.this, host, port, pass);
                launchVnc(host, port, pass, false);
            }
        });
    }

    private void checkLocalServices() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                isRfbActive = pingPort("127.0.0.1", 5901);
                isWebActive = pingPort("127.0.0.1", 6080);

                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        if (isRfbActive && isWebActive) {
                            tvLocalStatus.setText("🟢 VNC Server (5901) & noVNC (6080) are RUNNING");
                            tvLocalStatus.setTextColor(0xFF10B981); // Green
                        } else if (isRfbActive) {
                            tvLocalStatus.setText("🟡 VNC Server (5901) RUNNING | noVNC Offline");
                            tvLocalStatus.setTextColor(0xFFF59E0B); // Yellow
                        } else if (isWebActive) {
                            tvLocalStatus.setText("🟡 noVNC Web (6080) RUNNING | VNC Server Offline");
                            tvLocalStatus.setTextColor(0xFFF59E0B); // Yellow
                        } else {
                            tvLocalStatus.setText("🔴 Local VNC Server is Offline (Start with vncmanager.sh)");
                            tvLocalStatus.setTextColor(0xFFEF4444); // Red
                        }
                    }
                });
            }
        }).start();
    }

    private boolean pingPort(String host, int port) {
        try (Socket socket = new Socket()) {
            socket.connect(new InetSocketAddress(host, port), 600);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private String getPass() {
        String p = etPassword.getText().toString();
        return p.isEmpty() ? "vnc123" : p;
    }

    private int parsePort(String s, int defaultPort) {
        try {
            return Integer.parseInt(s.trim());
        } catch (Exception e) {
            return defaultPort;
        }
    }

    private void launchVnc(String host, int port, String pass, boolean isWeb) {
        Intent intent;
        if (isWeb) {
            intent = new Intent(this, VncWebActivity.class);
        } else {
            intent = new Intent(this, VncNativeActivity.class);
        }
        intent.putExtra("host", host);
        intent.putExtra("port", port);
        intent.putExtra("password", pass);
        startActivity(intent);
    }
}
