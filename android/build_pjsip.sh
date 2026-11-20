#!/bin/bash
# Builds pjproject for one ABI and merges it with openssl and opus into a single
# static library: /dist/android/<abi>/lib/libpjsip.a plus /dist/android/<abi>/include.
set -euo pipefail

TARGET_ARCH=${1:?Usage: $0 <armeabi-v7a|arm64-v8a>}
API_LEVEL="${ANDROID_API:?ANDROID_API must be set}"

BUILD_DIR="/tmp/pjsip"
INSTALL_DIR="/tmp/pjsip-install/${TARGET_ARCH}"
OUTPUT_DIR="/dist/android/${TARGET_ARCH}"
OPENSSL_DIR="/output/openssl/${TARGET_ARCH}"
OPUS_DIR="/output/opus/${TARGET_ARCH}"
TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64"

rm -rf "${BUILD_DIR}" "${INSTALL_DIR}" "${OUTPUT_DIR}"
cp -r /sources/pjsip "${BUILD_DIR}"
cp /sources/config_site.h "${BUILD_DIR}/pjlib/include/pj/config_site.h"

cd "${BUILD_DIR}"

# Tell configure-android which ABI & API level we want
export TARGET_ABI="${TARGET_ARCH}"
export APP_PLATFORM="${API_LEVEL}"  # NOTE: just "29", NOT "android-29"

# Do NOT override CC/CFLAGS/LDFLAGS – let configure-android + NDK decide
unset CC CXX CFLAGS CXXFLAGS LDFLAGS LIBS AR RANLIB NDK_TOOLCHAIN || true

./configure-android \
  --use-ndk-cflags \
  --prefix="${INSTALL_DIR}" \
  --with-ssl="${OPENSSL_DIR}" \
  --with-opus="${OPUS_DIR}" \
  --disable-video \
  --without-openh264

# Fail early if configure silently dropped TLS or opus support
if ! grep -Eq 'PJ_SSL_SOCK_IMP[[:space:]]+PJ_SSL_SOCK_IMP_OPENSSL' pjlib/include/pj/compat/os_auto.h; then
  echo "ERROR: pjproject was configured without OpenSSL" >&2
  exit 1
fi
if ! grep -Eq 'PJMEDIA_HAS_OPUS_CODEC[[:space:]]+1' pjmedia/include/pjmedia-codec/config_auto.h; then
  echo "ERROR: pjproject was configured without opus" >&2
  exit 1
fi

make dep
make
make install

# Merge pjproject (incl. third_party), openssl and opus into one archive.
# Libraries come from the build tree; the install step is used for headers only.
PJ_LIBS=(pjlib/lib/*.a pjlib-util/lib/*.a pjnath/lib/*.a pjmedia/lib/*.a pjsip/lib/*.a third_party/lib/*.a)
mkdir -p "${OUTPUT_DIR}/lib"
MRI_SCRIPT="create ${OUTPUT_DIR}/lib/libpjsip.a"
for lib in "${PJ_LIBS[@]/#/${BUILD_DIR}/}" "${OPENSSL_DIR}/lib/libssl.a" "${OPENSSL_DIR}/lib/libcrypto.a" "${OPUS_DIR}/lib/libopus.a"; do
  MRI_SCRIPT+=$'\n'"addlib ${lib}"
done
MRI_SCRIPT+=$'\n'"save"$'\n'"end"
echo "${MRI_SCRIPT}" | "${TOOLCHAIN}/bin/llvm-ar" -M
"${TOOLCHAIN}/bin/llvm-ranlib" "${OUTPUT_DIR}/lib/libpjsip.a"

cp -R "${INSTALL_DIR}/include" "${OUTPUT_DIR}/include"

# Clean up
rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
