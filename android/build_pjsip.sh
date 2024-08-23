#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/pjsip/${TARGET_ARCH}

# Copy PJSIP source code
rm -rf /tmp/pjsip
cp -r /sources/pjsip /tmp/pjsip

# Create a custom config_site.h for Android
cat <<EOF > "/tmp/pjsip/pjlib/include/pj/config_site.h"
#define PJ_ANDROID 1
#define PJ_CONFIG_ANDROID 1
#define PJ_HAS_STDINT_H 1
#define PJ_HAS_SYS_TIME_H 1
#define PJMEDIA_HAS_G729_CODEC 1
#define PJMEDIA_HAS_G7221_CODEC 1
#include <pj/config_site_sample.h>
#define PJMEDIA_HAS_VIDEO 0
#define PJMEDIA_AUDIO_DEV_HAS_ANDROID_JNI 0
#define PJMEDIA_AUDIO_DEV_HAS_OPENSL 1
#define PJSIP_AUTH_AUTO_SEND_NEXT 0
EOF

cd /tmp/pjsip

# Set up the environment for Android NDK cross-compilation
export TARGET_ABI=${TARGET_ARCH}
export APP_PLATFORM=android-${ANDROID_TARGET_API}

# Set the NDK paths and compiler based on the target architecture
export ANDROID_NDK_ROOT=/sources/android_ndk
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

# Set paths for the toolchain
export PATH=$TOOLCHAIN_PATH:$PATH

# Cross-compile flags for different architectures
if [ "$TARGET_ARCH" == "armeabi-v7a" ]; then
    export CC=$TOOLCHAIN_PATH/armv7a-linux-androideabi21-clang
    export CXX=$TOOLCHAIN_PATH/armv7a-linux-androideabi21-clang++
elif [ "$TARGET_ARCH" == "arm64-v8a" ]; then
    export CC=$TOOLCHAIN_PATH/aarch64-linux-android21-clang
    export CXX=$TOOLCHAIN_PATH/aarch64-linux-android21-clang++
elif [ "$TARGET_ARCH" == "x86_64" ]; then
    export CC=$TOOLCHAIN_PATH/x86_64-linux-android21-clang
    export CXX=$TOOLCHAIN_PATH/x86_64-linux-android21-clang++
else
    echo "Unsupported target ABI: $TARGET_ARCH"
    exit 1
fi

# Run PJSIP configuration for Android
./configure-android \
    --use-ndk-cflags \
    --with-ssl="/output/openssl/${TARGET_ARCH}" \
    --disable-video \
    --without-openh264 \
    --with-opus="/output/opus/${TARGET_ARCH}"
#    --with-openh264="/output/openh264/${TARGET_ARCH}" \

# Build PJSIP and SWIG bindings
make dep
make

cd /tmp/pjsip/pjsip-apps/src/swig
make

# Move the output files to the appropriate location
mkdir -p /output/pjsip/jniLibs/${TARGET_ARCH}/
mv ./java/android/app/src/main/jniLibs/**/libpjsua2.so /output/pjsip/jniLibs/${TARGET_ARCH}/

# Move Java bindings if they haven’t been moved already
if [ ! -d "/output/pjsip/java" ]; then
  mv ./java/android/app/src/main/java /output/pjsip/java
fi

# Clean up
rm -rf /tmp/pjsip
