#!/bin/bash
set -euo pipefail

TARGET_ARCH=${1:?Usage: $0 <armeabi-v7a|arm64-v8a|x86_64>}
API_LEVEL="${ANDROID_TARGET_API:-35}"  # or whatever you actually target

TARGET_PATH="/output/pjsip/${TARGET_ARCH}"

# Fresh copy of PJSIP sources
rm -rf /tmp/pjsip
cp -r /sources/pjsip /tmp/pjsip

# Create custom config_site.h for Android
cat <<EOF > "/tmp/pjsip/pjlib/include/pj/config_site.h"
#define PJ_ANDROID 1
#define PJ_CONFIG_ANDROID 1
#define PJ_HAS_STDINT_H 1
#define PJ_HAS_SYS_TIME_H 1
#define PJMEDIA_HAS_G729_CODEC 1
#define PJMEDIA_HAS_G7221_CODEC 1
#define PJMEDIA_HAS_VIDEO 0
#define PJMEDIA_AUDIO_DEV_HAS_ANDROID_JNI 0
#define PJMEDIA_AUDIO_DEV_HAS_OPENSL 1
#define PJSIP_AUTH_AUTO_SEND_NEXT 1
#define PJ_HAS_SSL_SOCK 1
#include <pj/config_site_sample.h>
EOF

cd /tmp/pjsip

# NDK root (must be the directory which contains build/core, ndk-build, toolchains, etc.)
export ANDROID_NDK_ROOT="/sources/android_ndk"

# Tell configure-android which ABI & API level we want
export TARGET_ABI="${TARGET_ARCH}"          # e.g. arm64-v8a
export APP_PLATFORM="${API_LEVEL}"          # NOTE: just "35", NOT "android-35"

# Do NOT override CC/CFLAGS/LDFLAGS – let configure-android + NDK decide
unset CC CXX CFLAGS CXXFLAGS LDFLAGS LIBS AR RANLIB NDK_TOOLCHAIN || true

export LDFLAGS="-Wl,-z,max-page-size=16384" # 16KB support

# Configure PJSIP for Android
./configure-android \
  --use-ndk-cflags \
  --with-ssl="/output/openssl/${TARGET_ARCH}" \
  --with-opus="/output/opus/${TARGET_ARCH}" \
  --disable-video \
  --without-openh264

# Build core libs
make dep
make

# Build SWIG Java bindings
cd /tmp/pjsip/pjsip-apps/src/swig
make

# Collect outputs

# SWIG Android module base
SWIG_ANDROID_DIR="/tmp/pjsip/pjsip-apps/src/swig/java/android/pjsua2/src/main"

# Map TARGET_ARCH -> NDK triple (for libc++_shared.so)
case "${TARGET_ARCH}" in
  arm64-v8a)
    NDK_TRIPLE="aarch64-linux-android"
    ;;
  armeabi-v7a)
    NDK_TRIPLE="arm-linux-androideabi"
    ;;
  x86_64)
    NDK_TRIPLE="x86_64-linux-android"
    ;;
  *)
    echo "Unsupported TARGET_ARCH: ${TARGET_ARCH}"
    exit 1
    ;;
esac

# Where we'll put JNI libs for this ABI in the final output
JNI_OUT="/output/pjsip/jniLibs/${TARGET_ARCH}"
mkdir -p "${JNI_OUT}"

# Exact paths for libpjsua2.so (from SWIG Android module) and libc++_shared.so (from NDK)
LIBPJSUA2_PATH="${SWIG_ANDROID_DIR}/jniLibs/${TARGET_ABI}/libpjsua2.so"
LIBC_SHARED_PATH="/sources/android_ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/${NDK_TRIPLE}/libc++_shared.so"

if [ ! -f "${LIBPJSUA2_PATH}" ]; then
  echo "ERROR: ${LIBPJSUA2_PATH} not found. SWIG/Android build may have failed."
  exit 1
fi

if [ ! -f "${LIBC_SHARED_PATH}" ]; then
  echo "ERROR: ${LIBC_SHARED_PATH} not found (NDK libc++_shared.so missing?)."
  exit 1
fi

# Copy JNI libs (PJSIP + C++ runtime) for this ABI
cp "${LIBPJSUA2_PATH}" "${JNI_OUT}/"
cp "${LIBC_SHARED_PATH}" "${JNI_OUT}/"

# Copy Java bindings only once (ABI-agnostic)
if [ ! -d "/output/pjsip/java" ]; then
  mkdir -p /output/pjsip/java
  if [ -d "${SWIG_ANDROID_DIR}/java" ]; then
    # Copy org/pjsip/... tree
    cp -R "${SWIG_ANDROID_DIR}/java/"* /output/pjsip/java/
  else
    echo "WARNING: ${SWIG_ANDROID_DIR}/java not found, skipping Java bindings copy."
  fi
fi

# Clean up
rm -rf /tmp/pjsip
