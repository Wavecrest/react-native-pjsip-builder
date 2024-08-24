#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/opus/${TARGET_ARCH}

cp -r /sources/opus /tmp/opus

cd /tmp/opus/jni

# Valid APP_ABI values: armeabi-v7a, arm64-v8a, x86_64
if [[ "$TARGET_ARCH" == "armeabi-v7a" || "$TARGET_ARCH" == "arm64-v8a" || "$TARGET_ARCH" == "x86_64" ]]; then
    APP_ABI="${TARGET_ARCH}"
else
    echo "Invalid architecture: $TARGET_ARCH"
    exit 1
fi

export APP_PLATFORM=android-29
# Set the NDK paths and compiler based on the target architecture
export ANDROID_NDK_ROOT=/sources/android_ndk/android-ndk-r25c
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"

if [ "$TARGET_ARCH" == "armeabi-v7a" ]; then
    export CC="armv7a-linux-androideabi29-clang"
    export CXX="armv7a-linux-androideabi29-clang++"
elif [ "$TARGET_ARCH" == "arm64-v8a" ]; then
    export CC="aarch64-linux-android29-clang"
    export CXX="aarch64-linux-android29-clang++"
elif [ "$TARGET_ARCH" == "x86_64" ]; then
    export CC="x86_64-linux-android29-clang"
    export CXX="x86_64-linux-android29-clang++"
else
    echo "Unsupported target architecture: $TARGET_ARCH"
    exit 1
fi

# Run ndk-build with the appropriate APP_ABI
ndk-build APP_ABI="${APP_ABI}"

mkdir -p ${TARGET_PATH}/include
mkdir -p ${TARGET_PATH}/lib

cp -r ../include ${TARGET_PATH}/include/opus
cp ../obj/local/${APP_ABI}/libopus.a ${TARGET_PATH}/lib/

# Clean up temporary directory
rm -rf /tmp/opus
