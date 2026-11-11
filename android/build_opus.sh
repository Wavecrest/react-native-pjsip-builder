#!/bin/bash
set -euo pipefail

TARGET_ARCH=${1:?Usage: $0 <armeabi-v7a|arm64-v8a|x86_64>}
API_LEVEL="${ANDROID_TARGET_API:-21}"

TARGET_PATH="/output/opus/${TARGET_ARCH}"
ANDROID_NDK="/sources/android_ndk"
TOOLCHAIN="${ANDROID_NDK}/toolchains/llvm/prebuilt/linux-x86_64"
SYSROOT="${TOOLCHAIN}/sysroot"

# Fresh copy of Opus sources (should be the unpacked opus-1.5.2 tarball)
rm -rf /tmp/opus
cp -r /sources/opus /tmp/opus
cd /tmp/opus

case "$TARGET_ARCH" in
  armeabi-v7a)
    HOST_TRIPLE="armv7a-linux-androideabi"
    CC_BIN="${HOST_TRIPLE}${API_LEVEL}-clang"
    ;;
  arm64-v8a)
    HOST_TRIPLE="aarch64-linux-android"
    CC_BIN="${HOST_TRIPLE}${API_LEVEL}-clang"
    ;;
  x86_64)
    HOST_TRIPLE="x86_64-linux-android"
    CC_BIN="${HOST_TRIPLE}${API_LEVEL}-clang"
    ;;
  *)
    echo "Unsupported TARGET_ARCH: ${TARGET_ARCH}"
    exit 1
    ;;
esac

export PATH="${TOOLCHAIN}/bin:${PATH}"
export CC="${CC_BIN}"
export AR="llvm-ar"
export RANLIB="llvm-ranlib"

export CFLAGS="--sysroot=${SYSROOT} -fPIC -D__ANDROID_API__=${API_LEVEL}"
export LDFLAGS="--sysroot=${SYSROOT}"

# Configure Opus for cross-compile
./configure \
  --host="${HOST_TRIPLE}" \
  --disable-shared \
  --enable-static \
  --with-pic \
  --disable-extra-programs \
  --disable-doc \
  --disable-asm \
  --prefix="${TARGET_PATH}"

make clean
make -j"$(nproc)"
make install

# At this point you have:
#   ${TARGET_PATH}/lib/libopus.a
#   ${TARGET_PATH}/include/opus/...

# Clean up
rm -rf /tmp/opus
