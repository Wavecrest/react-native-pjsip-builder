#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/openssl/${TARGET_ARCH}

# Clean up the previous build directory if it exists
rm -rf /tmp/openssl
cp -r /sources/openssl /tmp/openssl

if [ "$TARGET_ARCH" == "armeabi-v7a" ]; then
    TARGET="android-arm"
    TOOLCHAIN="arm-linux-androideabi"
elif [ "$TARGET_ARCH" == "arm64-v8a" ]; then
    TARGET="android-arm64"
    TOOLCHAIN="aarch64-linux-android"
elif [ "$TARGET_ARCH" == "x86_64" ]; then
    if [[ "$TARGET_OS" == "android" ]]; then
        TARGET="android-x86_64"
        TOOLCHAIN="x86_64-linux-android"
    else
        TARGET="linux-x86_64"
    fi
else
    echo "Unsupported target ABI: $TARGET_ARCH"
    exit 1
fi

# Set the NDK paths and compiler based on the target architecture
export ANDROID_NDK_ROOT=/sources/android_ndk
export PATH="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
export PATH=$TOOLCHAIN_PATH:$PATH
export CC=$TOOLCHAIN_PATH/${TOOLCHAIN}21-clang
export CXX=$TOOLCHAIN_PATH/${TOOLCHAIN}21-clang++
export LINK=${CXX}

cd /tmp/openssl

# Configure and build OpenSSL for the specified target
./Configure $TARGET no-asm no-shared --prefix=$TARGET_PATH --openssldir=$TARGET_PATH
make clean
make
make install

# Clean up the build directory after completion
rm -rf /tmp/openssl
