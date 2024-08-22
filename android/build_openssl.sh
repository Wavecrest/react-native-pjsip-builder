#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/openssl/${TARGET_ARCH}

cp -r /sources/openssl /tmp/openssl

if [ "$TARGET_ARCH" == "armeabi-v7a" ]; then
    TARGET="android-arm"
    TOOLCHAIN_PREFIX="armv7a-linux-androideabi"
    API_LEVEL=21
elif [ "$TARGET_ARCH" == "arm64-v8a" ]; then
    TARGET="android-arm64"
    TOOLCHAIN_PREFIX="aarch64-linux-android"
    API_LEVEL=21
elif [ "$TARGET_ARCH" == "x86_64" ]; then
    TARGET="android-x86_64"
    TOOLCHAIN_PREFIX="x86_64-linux-android"
    API_LEVEL=21
else
    echo "Unsupported target ABI: $TARGET_ARCH"
    exit 1
fi

# Set the NDK path and toolchain path dynamically
NDK_PATH=/sources/android_ndk
TOOLCHAIN_PATH=$(find $NDK_PATH/toolchains/llvm/prebuilt -type d -name "linux-*" | head -n 1)

# Set environment variables for cross-compilation
export PATH=$TOOLCHAIN_PATH/bin:$PATH
export CC="$TOOLCHAIN_PATH/bin/${TOOLCHAIN_PREFIX}${API_LEVEL}-clang"
export CXX="$TOOLCHAIN_PATH/bin/${TOOLCHAIN_PREFIX}${API_LEVEL}-clang++"
export AR="$TOOLCHAIN_PATH/bin/llvm-ar"
export AS="$TOOLCHAIN_PATH/bin/llvm-as"
export LD="$TOOLCHAIN_PATH/bin/ld"
export RANLIB="$TOOLCHAIN_PATH/bin/llvm-ranlib"
export STRIP="$TOOLCHAIN_PATH/bin/llvm-strip"
export ANDROID_NDK_HOME=$NDK_PATH

# Go to the OpenSSL source directory
cd /tmp/openssl/

# Explicitly set the cross-compiler flags
./Configure $TARGET no-asm no-shared --prefix=$TARGET_PATH --openssldir=$TARGET_PATH -D__ANDROID_API__=$API_LEVEL

make -j$(nproc)
make install

# Clean up
rm -rf /tmp/openssl/
