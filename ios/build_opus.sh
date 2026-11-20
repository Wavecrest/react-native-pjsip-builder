#!/bin/bash
# Builds static opus for one iOS slice into ${WORK_DIR}/out/<slice>/opus
set -euo pipefail

SLICE=${1:?Usage: $0 <ios-arm64|ios-arm64-simulator>}
: "${WORK_DIR:?WORK_DIR must be set}" "${IOS_MIN_VERSION:?IOS_MIN_VERSION must be set}"

BUILD_DIR="${WORK_DIR}/build/${SLICE}/opus"
TARGET_PATH="${WORK_DIR}/out/${SLICE}/opus"

case "${SLICE}" in
  ios-arm64)
    SDK="iphoneos"
    MIN_FLAG="-miphoneos-version-min=${IOS_MIN_VERSION}"
    ;;
  ios-arm64-simulator)
    SDK="iphonesimulator"
    MIN_FLAG="-mios-simulator-version-min=${IOS_MIN_VERSION}"
    ;;
  *)
    echo "Unsupported slice: ${SLICE}" >&2
    exit 1
    ;;
esac

SDK_PATH="$(xcrun --sdk "${SDK}" --show-sdk-path)"

rm -rf "${BUILD_DIR}" "${TARGET_PATH}"
mkdir -p "$(dirname "${BUILD_DIR}")"
cp -R "${WORK_DIR}/src/opus" "${BUILD_DIR}"
cd "${BUILD_DIR}"

export CC="$(xcrun --sdk "${SDK}" -f clang)"
export CFLAGS="-arch arm64 -isysroot ${SDK_PATH} ${MIN_FLAG} -O2 -fPIC"
export LDFLAGS="-arch arm64 -isysroot ${SDK_PATH} ${MIN_FLAG}"

./configure \
  --host=aarch64-apple-darwin \
  --disable-shared \
  --enable-static \
  --with-pic \
  --disable-extra-programs \
  --disable-doc \
  --disable-asm \
  --prefix="${TARGET_PATH}"

make -j"$(sysctl -n hw.ncpu)"
make install

rm -rf "${BUILD_DIR}"
