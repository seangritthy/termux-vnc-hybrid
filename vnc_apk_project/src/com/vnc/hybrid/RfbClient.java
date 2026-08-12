package com.vnc.hybrid;

import android.graphics.Bitmap;
import android.graphics.Color;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;

public class RfbClient {

    public interface RfbListener {
        void onConnected(int width, int height, String name);
        void onFrameUpdated(Bitmap bitmap);
        void onError(String errorMsg);
        void onDisconnected();
    }

    private final String host;
    private final int port;
    private final String password;
    private final RfbListener listener;

    private Socket socket;
    private DataInputStream in;
    private DataOutputStream out;

    private int fbWidth;
    private int fbHeight;
    private Bitmap framebufferBitmap;
    private int[] pixels;

    private volatile boolean isRunning = false;

    public RfbClient(String host, int port, String password, RfbListener listener) {
        this.host = host;
        this.port = port;
        this.password = password;
        this.listener = listener;
    }

    public void start() {
        new Thread(new Runnable() {
            @Override
            public void run() {
                runClient();
            }
        }).start();
    }

    public void stop() {
        isRunning = false;
        try {
            if (socket != null) socket.close();
        } catch (Exception ignored) {}
    }

    private void runClient() {
        try {
            socket = new Socket(host, port);
            socket.setTcpNoDelay(true);
            in = new DataInputStream(socket.getInputStream());
            out = new DataOutputStream(socket.getOutputStream());

            // 1. RFB Handshake
            byte[] ver = new byte[12];
            in.readFully(ver);
            String serverVer = new String(ver, StandardCharsets.US_ASCII);

            String clientVerStr = "RFB 003.008\n";
            if (serverVer.startsWith("RFB 003.003")) clientVerStr = "RFB 003.003\n";
            else if (serverVer.startsWith("RFB 003.007")) clientVerStr = "RFB 003.007\n";

            out.write(clientVerStr.getBytes(StandardCharsets.US_ASCII));
            out.flush();

            // 2. Security Handshake
            int secType = 0;
            if (clientVerStr.contains("003.003")) {
                secType = in.readInt();
            } else {
                int numTypes = in.readUnsignedByte();
                byte[] types = new byte[numTypes];
                in.readFully(types);
                for (byte t : types) {
                    if (t == 1 || t == 2) { // 1 = None, 2 = VNC Auth
                        secType = t & 0xFF;
                        break;
                    }
                }
                out.writeByte(secType);
                out.flush();
            }

            if (secType == 2) { // VNC Authentication
                byte[] challenge = new byte[16];
                in.readFully(challenge);

                byte[] key = prepareDesKey(password);
                byte[] response = encryptDes(challenge, key);
                out.write(response);
                out.flush();

                int authResult = in.readInt();
                if (authResult != 0) {
                    listener.onError("VNC Authentication Failed (Wrong Password)");
                    return;
                }
            } else if (secType != 1 && secType != 0) {
                listener.onError("Unsupported Security Type: " + secType);
                return;
            }

            if (!clientVerStr.contains("003.003") && secType != 1) {
                int result = in.readInt();
                if (result != 0) {
                    listener.onError("VNC Auth failed");
                    return;
                }
            }

            // 3. ClientInit (Shared = 1)
            out.writeByte(1);
            out.flush();

            // 4. ServerInit
            fbWidth = in.readUnsignedShort();
            fbHeight = in.readUnsignedShort();

            // Pixel Format (16 bytes)
            byte[] pixelFormat = new byte[16];
            in.readFully(pixelFormat);

            int nameLen = in.readInt();
            byte[] nameBytes = new byte[nameLen];
            in.readFully(nameBytes);
            String desktopName = new String(nameBytes, StandardCharsets.UTF_8);

            pixels = new int[fbWidth * fbHeight];
            framebufferBitmap = Bitmap.createBitmap(fbWidth, fbHeight, Bitmap.Config.ARGB_8888);

            // Set Pixel Format to 32-bit RGBA
            setPixelFormat();

            listener.onConnected(fbWidth, fbHeight, desktopName);

            isRunning = true;

            // 5. Main Loop: Request Framebuffer Update & Read Rectangles
            while (isRunning && !socket.isClosed()) {
                sendFramebufferUpdateRequest(0, 0, fbWidth, fbHeight, false);
                readServerMessageType();
            }

        } catch (Exception e) {
            if (isRunning) {
                listener.onError("Connection Error: " + e.getMessage());
            }
        } finally {
            isRunning = false;
            listener.onDisconnected();
        }
    }

    private void setPixelFormat() throws Exception {
        byte[] msg = new byte[20];
        msg[0] = 0; // SetPixelFormat
        msg[4] = 32; // bits-per-pixel
        msg[5] = 24; // depth
        msg[6] = 0;  // big-endian
        msg[7] = 1;  // true-color
        msg[8] = 0; msg[9] = (byte) 255; // red-max
        msg[10] = 0; msg[11] = (byte) 255; // green-max
        msg[12] = 0; msg[13] = (byte) 255; // blue-max
        msg[14] = 16; // red-shift
        msg[15] = 8;  // green-shift
        msg[16] = 0;  // blue-shift
        out.write(msg);
        out.flush();
    }

    private void sendFramebufferUpdateRequest(int x, int y, int w, int h, boolean incremental) throws Exception {
        byte[] msg = new byte[10];
        msg[0] = 3; // FramebufferUpdateRequest
        msg[1] = (byte) (incremental ? 1 : 0);
        msg[2] = (byte) (x >> 8); msg[3] = (byte) x;
        msg[4] = (byte) (y >> 8); msg[5] = (byte) y;
        msg[6] = (byte) (w >> 8); msg[7] = (byte) w;
        msg[8] = (byte) (h >> 8); msg[9] = (byte) h;
        out.write(msg);
        out.flush();
    }

    private void readServerMessageType() throws Exception {
        int msgType = in.readUnsignedByte();
        if (msgType == 0) { // FramebufferUpdate
            in.readByte(); // padding
            int numRects = in.readUnsignedShort();
            for (int r = 0; r < numRects; r++) {
                int rx = in.readUnsignedShort();
                int ry = in.readUnsignedShort();
                int rw = in.readUnsignedShort();
                int rh = in.readUnsignedShort();
                int encoding = in.readInt();

                if (encoding == 0) { // Raw Encoding
                    for (int y = ry; y < ry + rh; y++) {
                        for (int x = rx; x < rx + rw; x++) {
                            int b = in.readUnsignedByte();
                            int g = in.readUnsignedByte();
                            int rCol = in.readUnsignedByte();
                            in.readByte(); // skip alpha
                            if (x < fbWidth && y < fbHeight) {
                                pixels[y * fbWidth + x] = Color.rgb(rCol, g, b);
                            }
                        }
                    }
                }
            }
            framebufferBitmap.setPixels(pixels, 0, fbWidth, 0, 0, fbWidth, fbHeight);
            listener.onFrameUpdated(framebufferBitmap);
        }
    }

    public void sendPointerEvent(int x, int y, int buttonMask) {
        if (!isRunning || out == null) return;
        try {
            byte[] msg = new byte[6];
            msg[0] = 5; // PointerEvent
            msg[1] = (byte) buttonMask;
            msg[2] = (byte) (x >> 8); msg[3] = (byte) x;
            msg[4] = (byte) (y >> 8); msg[5] = (byte) y;
            synchronized (out) {
                out.write(msg);
                out.flush();
            }
        } catch (Exception ignored) {}
    }

    public void sendKeyEvent(int keysym, boolean down) {
        if (!isRunning || out == null) return;
        try {
            byte[] msg = new byte[8];
            msg[0] = 4; // KeyEvent
            msg[1] = (byte) (down ? 1 : 0);
            msg[2] = 0; msg[3] = 0; // padding
            msg[4] = (byte) (keysym >> 24); msg[5] = (byte) (keysym >> 16);
            msg[6] = (byte) (keysym >> 8); msg[7] = (byte) keysym;
            synchronized (out) {
                out.write(msg);
                out.flush();
            }
        } catch (Exception ignored) {}
    }

    private byte[] prepareDesKey(String pass) {
        byte[] key = new byte[8];
        byte[] passBytes = pass.getBytes(StandardCharsets.US_ASCII);
        for (int i = 0; i < 8; i++) {
            if (i < passBytes.length) {
                key[i] = reverseByte(passBytes[i]);
            } else {
                key[i] = 0;
            }
        }
        return key;
    }

    private byte reverseByte(byte b) {
        int val = b & 0xFF;
        int rev = 0;
        for (int i = 0; i < 8; i++) {
            rev = (rev << 1) | (val & 1);
            val >>= 1;
        }
        return (byte) rev;
    }

    private byte[] encryptDes(byte[] data, byte[] key) throws Exception {
        SecretKeySpec keySpec = new SecretKeySpec(key, "DES");
        Cipher cipher = Cipher.getInstance("DES/ECB/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, keySpec);
        return cipher.doFinal(data);
    }
}
