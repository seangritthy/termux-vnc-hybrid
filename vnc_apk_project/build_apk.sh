#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
GEN_DIR="$PROJECT_DIR/gen"
BIN_DIR="$PROJECT_DIR/bin"
SRC_DIR="$PROJECT_DIR/src"
RES_DIR="$PROJECT_DIR/res"
MANIFEST="$PROJECT_DIR/AndroidManifest.xml"
ANDROID_JAR="$PROJECT_DIR/android.jar"
KEYSTORE="$PROJECT_DIR/debug.keystore"
OUTPUT_APK_NAME="vnc-hybrid-client.apk"
FINAL_APK="$BIN_DIR/$OUTPUT_APK_NAME"
SDCARD_DOWNLOAD="/sdcard/Download"
EMULATED_DOWNLOAD="/storage/emulated/0/Download"

echo "=== 🚀 Rebuilding VNC Hybrid Client APK (Target SDK 34 + ZipAligned) ==="

# Clean build workspace
rm -rf "$BUILD_DIR" "$GEN_DIR" "$BIN_DIR"
mkdir -p "$BUILD_DIR" "$GEN_DIR" "$BIN_DIR"

# 1. Package resources and generate R.java
echo "1. Generating R.java with AAPT..."
aapt package -f -m \
    -J "$GEN_DIR" \
    -M "$MANIFEST" \
    -S "$RES_DIR" \
    -I "$ANDROID_JAR"

# 2. Compile Java source files
echo "2. Compiling Java sources with javac..."
find "$SRC_DIR" "$GEN_DIR" -name "*.java" > "$BUILD_DIR/sources.txt"

javac -encoding UTF-8 \
    -source 8 -target 8 \
    -bootclasspath "$ANDROID_JAR" \
    -d "$BUILD_DIR" \
    @"${BUILD_DIR}/sources.txt"

# 3. Convert .class files to classes.dex using d8/r8
echo "3. Converting bytecode to classes.dex..."
find "$BUILD_DIR" -name "*.class" > "$BUILD_DIR/classes.txt"

if command -v d8 >/dev/null 2>&1; then
    d8 --min-api 24 --output "$BIN_DIR" @"${BUILD_DIR}/classes.txt" --lib "$ANDROID_JAR"
else
    if [ ! -f "/tmp/r8.jar" ]; then
        echo "   [+] Downloading r8.jar helper..."
        curl -sSL -o /tmp/r8.jar https://storage.googleapis.com/r8-releases/raw/8.2.42/r8.jar
    fi
    java -cp /tmp/r8.jar com.android.tools.r8.D8 --min-api 24 --output "$BIN_DIR" @"${BUILD_DIR}/classes.txt" --lib "$ANDROID_JAR"
fi

# 4. Package initial unaligned APK
echo "4. Packaging APK resources..."
UNALIGNED_APK="$BIN_DIR/unaligned.apk"
aapt package -f \
    -M "$MANIFEST" \
    -S "$RES_DIR" \
    -I "$ANDROID_JAR" \
    -F "$UNALIGNED_APK"

# 5. Add classes.dex into unaligned APK
echo "5. Adding classes.dex to APK..."
cd "$BIN_DIR"
aapt add -v "unaligned.apk" "classes.dex"
cd "$PROJECT_DIR"

# 6. ZipAlign 4-byte boundary for Android PackageInstaller
echo "6. Aligning APK with zipalign..."
ALIGNED_APK="$BIN_DIR/aligned.apk"
zipalign -v -p 4 "$UNALIGNED_APK" "$ALIGNED_APK"

# 7. Generate signing keystore if missing
if [ ! -f "$KEYSTORE" ]; then
    echo "7. Generating debug signing key..."
    keytool -genkey -v \
        -keystore "$KEYSTORE" \
        -alias androiddebugkey \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass android \
        -keypass android \
        -dname "CN=Android Debug,O=Android,C=US"
fi

# 8. Sign the aligned APK with apksigner
echo "8. Signing aligned APK with apksigner..."
SIGNED_APK="$BIN_DIR/$OUTPUT_APK_NAME"
apksigner sign --ks "$KEYSTORE" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --ks-key-alias androiddebugkey \
    --out "$SIGNED_APK" \
    "$ALIGNED_APK"

echo "=== ✅ Verification ==="
apksigner verify -v "$SIGNED_APK"

# Copy output to root project bin directory if exists
if [ -d "$PROJECT_DIR/../bin" ]; then
    cp -vf "$SIGNED_APK" "$PROJECT_DIR/../bin/$OUTPUT_APK_NAME" 2>/dev/null || true
fi

# 9. Release to /sdcard/Download/ and /storage/emulated/0/Download/
echo "9. Copying APK to Downloads..."
cp -vf "$SIGNED_APK" "$SDCARD_DOWNLOAD/$OUTPUT_APK_NAME" 2>/dev/null || true
cp -vf "$SIGNED_APK" "$EMULATED_DOWNLOAD/$OUTPUT_APK_NAME" 2>/dev/null || true
chmod 666 "$SDCARD_DOWNLOAD/$OUTPUT_APK_NAME" "$EMULATED_DOWNLOAD/$OUTPUT_APK_NAME" 2>/dev/null || true

echo "🎉 APK successfully built and released to: $SIGNED_APK"


