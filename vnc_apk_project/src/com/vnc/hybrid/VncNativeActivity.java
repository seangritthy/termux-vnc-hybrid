package com.vnc.hybrid;

import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.Button;
import android.widget.HorizontalScrollView;
import android.widget.Toast;

public class VncNativeActivity extends Activity implements RfbClient.RfbListener {

    private VncCanvasView vncCanvas;
    private RfbClient rfbClient;

    private Button btnMouse;
    private HorizontalScrollView scrollKeys;
    private int currentMouseMask = 1; // 1 = Left, 2 = Middle, 4 = Right

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_vnc_native);

        String host = getIntent().getStringExtra("host");
        int port = getIntent().getIntExtra("port", 5901);
        String pass = getIntent().getStringExtra("password");

        vncCanvas = findViewById(R.id.vnc_canvas);
        btnMouse = findViewById(R.id.btn_rfb_mouse);
        scrollKeys = findViewById(R.id.scroll_special_keys);

        Button btnKbd = findViewById(R.id.btn_rfb_kbd);
        Button btnKeys = findViewById(R.id.btn_rfb_keys);
        Button btnClose = findViewById(R.id.btn_rfb_close);

        rfbClient = new RfbClient(host, port, pass, this);
        vncCanvas.setRfbClient(rfbClient);
        rfbClient.start();

        Toast.makeText(this, "Connecting RFB to " + host + ":" + port + "...", Toast.LENGTH_SHORT).show();

        btnKbd.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                toggleKeyboard();
            }
        });

        btnKeys.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                int vis = scrollKeys.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE;
                scrollKeys.setVisibility(vis);
            }
        });

        btnMouse.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                cycleMouseMode();
            }
        });

        btnClose.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        setupSpecialKeys();
    }

    private void cycleMouseMode() {
        if (currentMouseMask == 1) {
            currentMouseMask = 4; // Right Click
            btnMouse.setText("🖱️ Right Click");
        } else if (currentMouseMask == 4) {
            currentMouseMask = 2; // Middle Click
            btnMouse.setText("🖱️ Middle Click");
        } else {
            currentMouseMask = 1; // Left Click
            btnMouse.setText("🖱️ Left Click");
        }
        vncCanvas.setMouseMask(currentMouseMask);
    }

    private void setupSpecialKeys() {
        findViewById(R.id.key_esc).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFF1B); }
        });
        findViewById(R.id.key_tab).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFF09); }
        });
        findViewById(R.id.key_ctrl).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFFE3); }
        });
        findViewById(R.id.key_alt).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFFE9); }
        });
        findViewById(R.id.key_up).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFF52); }
        });
        findViewById(R.id.key_down).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFF54); }
        });
        findViewById(R.id.key_left).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFF51); }
        });
        findViewById(R.id.key_right).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { sendKey(0xFF53); }
        });
        findViewById(R.id.key_cad).setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                sendKey(0xFFE3); // Ctrl
                sendKey(0xFFE9); // Alt
                sendKey(0xFFFF); // Delete
            }
        });
    }

    private void sendKey(int keysym) {
        if (rfbClient != null) {
            rfbClient.sendKeyEvent(keysym, true);
            vncCanvas.postDelayed(new Runnable() {
                @Override
                public void run() {
                    rfbClient.sendKeyEvent(keysym, false);
                }
            }, 50);
        }
    }

    private void toggleKeyboard() {
        InputMethodManager imm = (InputMethodManager) getSystemService(Context.INPUT_METHOD_SERVICE);
        if (imm != null) {
            imm.toggleSoftInput(InputMethodManager.SHOW_FORCED, 0);
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (rfbClient != null) {
            int keysym = androidKeyToKeysym(keyCode, event);
            if (keysym != 0) {
                rfbClient.sendKeyEvent(keysym, true);
                return true;
            }
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (rfbClient != null) {
            int keysym = androidKeyToKeysym(keyCode, event);
            if (keysym != 0) {
                rfbClient.sendKeyEvent(keysym, false);
                return true;
            }
        }
        return super.onKeyUp(keyCode, event);
    }

    private int androidKeyToKeysym(int keyCode, KeyEvent event) {
        if (event.getUnicodeChar() > 0) return event.getUnicodeChar();
        switch (keyCode) {
            case KeyEvent.KEYCODE_DEL: return 0xFF08; // Backspace
            case KeyEvent.KEYCODE_ENTER: return 0xFF0D; // Return
            case KeyEvent.KEYCODE_TAB: return 0xFF09;
            case KeyEvent.KEYCODE_ESCAPE: return 0xFF1B;
            case KeyEvent.KEYCODE_DPAD_UP: return 0xFF52;
            case KeyEvent.KEYCODE_DPAD_DOWN: return 0xFF54;
            case KeyEvent.KEYCODE_DPAD_LEFT: return 0xFF51;
            case KeyEvent.KEYCODE_DPAD_RIGHT: return 0xFF53;
            default: return 0;
        }
    }

    @Override
    public void onConnected(final int width, final int height, final String name) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(VncNativeActivity.this, "Connected: " + name + " (" + width + "x" + height + ")", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onFrameUpdated(Bitmap bitmap) {
        vncCanvas.setFramebuffer(bitmap);
    }

    @Override
    public void onError(final String errorMsg) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(VncNativeActivity.this, errorMsg, Toast.LENGTH_LONG).show();
            }
        });
    }

    @Override
    public void onDisconnected() {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Toast.makeText(VncNativeActivity.this, "Disconnected", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (rfbClient != null) {
            rfbClient.stop();
        }
    }
}
