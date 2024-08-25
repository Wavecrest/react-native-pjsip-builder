#!/bin/bash
set -e -x -v

TARGET_ARCH=$1
TARGET_PATH=/output/openssl/${TARGET_ARCH}

# Clean up the previous build directory if it exists
rm -rf /tmp/openssl
cp -r /sources/openssl /tmp/openssl

# Define the NDK path
export ANDROID_NDK_HOME="/sources/android_ndk"
export ANDROID_NDK="/sources/android_ndk"

if [ "$TARGET_ARCH" == "armeabi-v7a" ]; then
    TARGET="android-arm"
    TOOLCHAIN="armv7a-linux-androideabi29"
    ARCH_FLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=vfpv3-d16 -fPIC"
    ARCH_LINK="-march=armv7-a -Wl,--fix-cortex-a8"
elif [ "$TARGET_ARCH" == "arm64-v8a" ]; then
    TARGET="android-arm64"
    TOOLCHAIN="aarch64-linux-android29"
    ARCH_FLAGS="-fPIC"
    ARCH_LINK=""
else
    echo "Unsupported target ABI: $TARGET_ARCH"
    exit 1
fi

# Set the NDK paths and compiler based on the target architecture
export TOOLCHAIN_PATH="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin"
export PATH="$TOOLCHAIN_PATH:$PATH"
export CC="${TOOLCHAIN_PATH}/${TOOLCHAIN}-clang"
export CXX="${TOOLCHAIN_PATH}/${TOOLCHAIN}-clang++"
export LINK="$CXX"
export AR="${TOOLCHAIN_PATH}/llvm-ar"
export RANLIB="${TOOLCHAIN_PATH}/llvm-ranlib"

# Add -fPIC explicitly
export CFLAGS="${ARCH_FLAGS} -ffunction-sections -funwind-tables -fstack-protector-strong -fno-strict-aliasing -D__ANDROID_API__=29"
export LDFLAGS="${ARCH_LINK}"

cd /tmp/openssl

# Configure and build OpenSSL for the specified target
./Configure $TARGET no-asm no-shared no-unit-test --prefix=$TARGET_PATH --openssldir=$TARGET_PATH -fPIC -D__ANDROID_API__=29

make clean
make
make install

# Clean up the build directory after completion
rm -rf /tmp/openssl
