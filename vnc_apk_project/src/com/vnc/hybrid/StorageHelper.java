package com.vnc.hybrid;

import android.content.Context;
import android.content.SharedPreferences;

public class StorageHelper {
    private static final String PREF_NAME = "vnc_hybrid_prefs";
    private static final String KEY_HOST = "vnc_host";
    private static final String KEY_PORT = "vnc_port";
    private static final String KEY_PASS = "vnc_password";

    public static void saveLastConnection(Context ctx, String host, int port, String password) {
        SharedPreferences sp = ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        sp.edit()
          .putString(KEY_HOST, host)
          .putInt(KEY_PORT, port)
          .putString(KEY_PASS, password)
          .apply();
    }

    public static String getSavedHost(Context ctx) {
        SharedPreferences sp = ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        return sp.getString(KEY_HOST, "127.0.0.1");
    }

    public static int getSavedPort(Context ctx, boolean isWeb) {
        SharedPreferences sp = ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        return sp.getInt(KEY_PORT, isWeb ? 6080 : 5901);
    }

    public static String getSavedPassword(Context ctx) {
        SharedPreferences sp = ctx.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        return sp.getString(KEY_PASS, "vnc123");
    }
}
