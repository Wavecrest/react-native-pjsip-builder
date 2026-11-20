#!/bin/bash
# Builds pjproject for one iOS slice and merges it with openssl and opus into a
# single static library: ${WORK_DIR}/out/<slice>/pjsip/{lib/libpjsip.a,include}
set -euo pipefail

SLICE=${1:?Usage: $0 <ios-arm64|ios-arm64-simulator>}
: "${WORK_DIR:?WORK_DIR must be set}" "${IOS_MIN_VERSION:?IOS_MIN_VERSION must be set}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${WORK_DIR}/build/${SLICE}/pjsip"
INSTALL_DIR="${WORK_DIR}/build/${SLICE}/pjsip-install"
OUTPUT_DIR="${WORK_DIR}/out/${SLICE}/pjsip"
OPENSSL_DIR="${WORK_DIR}/out/${SLICE}/openssl"
OPUS_DIR="${WORK_DIR}/out/${SLICE}/opus"
XCODE_DEV_PATH="$(xcode-select -p)"

case "${SLICE}" in
  ios-arm64)
    export DEVPATH="${XCODE_DEV_PATH}/Platforms/iPhoneOS.platform/Developer"
    export MIN_IOS="-miphoneos-version-min=${IOS_MIN_VERSION}"
    ;;
  ios-arm64-simulator)
    export DEVPATH="${XCODE_DEV_PATH}/Platforms/iPhoneSimulator.platform/Developer"
    export MIN_IOS="-mios-simulator-version-min=${IOS_MIN_VERSION}"
    ;;
  *)
    echo "Unsupported slice: ${SLICE}" >&2
    exit 1
    ;;
esac
export ARCH="-arch arm64"

rm -rf "${BUILD_DIR}" "${INSTALL_DIR}" "${OUTPUT_DIR}"
mkdir -p "$(dirname "${BUILD_DIR}")"
cp -R "${WORK_DIR}/src/pjsip" "${BUILD_DIR}"
cp "${ROOT_DIR}/ios/config_site.h" "${BUILD_DIR}/pjlib/include/pj/config_site.h"
cd "${BUILD_DIR}"

./configure-iphone \
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
xcrun libtool -static -o "${OUTPUT_DIR}/lib/libpjsip.a" \
  "${PJ_LIBS[@]}" \
  "${OPENSSL_DIR}/lib/libssl.a" \
  "${OPENSSL_DIR}/lib/libcrypto.a" \
  "${OPUS_DIR}/lib/libopus.a"

cp -R "${INSTALL_DIR}/include" "${OUTPUT_DIR}/include"

rm -rf "${BUILD_DIR}" "${INSTALL_DIR}"
