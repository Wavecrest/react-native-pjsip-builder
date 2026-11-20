#!/bin/bash
# Builds static OpenSSL for one iOS slice into ${WORK_DIR}/out/<slice>/openssl
set -euo pipefail

SLICE=${1:?Usage: $0 <ios-arm64|ios-arm64-simulator>}
: "${WORK_DIR:?WORK_DIR must be set}" "${IOS_MIN_VERSION:?IOS_MIN_VERSION must be set}"

BUILD_DIR="${WORK_DIR}/build/${SLICE}/openssl"
TARGET_PATH="${WORK_DIR}/out/${SLICE}/openssl"

case "${SLICE}" in
  ios-arm64)
    TARGET="ios64-xcrun"
    MIN_FLAG="-mios-version-min=${IOS_MIN_VERSION}"
    ;;
  ios-arm64-simulator)
    TARGET="iossimulator-arm64-xcrun"
    MIN_FLAG="-mios-simulator-version-min=${IOS_MIN_VERSION}"
    ;;
  *)
    echo "Unsupported slice: ${SLICE}" >&2
    exit 1
    ;;
esac

rm -rf "${BUILD_DIR}" "${TARGET_PATH}"
mkdir -p "$(dirname "${BUILD_DIR}")"
cp -R "${WORK_DIR}/src/openssl" "${BUILD_DIR}"
cd "${BUILD_DIR}"

./Configure \
  "${TARGET}" \
  no-asm no-shared no-module no-unit-test \
  --prefix="${TARGET_PATH}" \
  --openssldir="${TARGET_PATH}" \
  --libdir=lib \
  "${MIN_FLAG}"

make -j"$(sysctl -n hw.ncpu)" build_libs
make install_dev

rm -rf "${BUILD_DIR}"
