#!/bin/bash
# Builds pjsip.xcframework (static, device arm64 + simulator arm64). Runs on a
# macOS host with Xcode; iOS toolchains cannot run in Docker.
# Output: dist/ios/pjsip.xcframework
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${ROOT_DIR}/versions.env"
cd "${ROOT_DIR}"

if [ "$(uname)" != "Darwin" ] || ! command -v xcodebuild > /dev/null; then
  echo "ERROR: iOS build requires macOS with Xcode installed" >&2
  exit 1
fi

./fetch_sources.sh ios

export IOS_MIN_VERSION
# pjproject/openssl makefiles break on paths with spaces, so build in a temp dir.
# It is kept on failure for debugging.
export WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pjsip-ios.XXXXXX")"
echo "Building in ${WORK_DIR}"
SLICES="ios-arm64 ios-arm64-simulator"

rm -rf ./dist/ios
mkdir -p "${WORK_DIR}/src/pjsip" "${WORK_DIR}/src/openssl" "${WORK_DIR}/src/opus" ./dist/ios

tar xzf "sources/pjproject-${PJSIP_VERSION}.tar.gz" -C "${WORK_DIR}/src/pjsip" --strip-components=1
tar xzf "sources/openssl-${OPENSSL_VERSION}.tar.gz" -C "${WORK_DIR}/src/openssl" --strip-components=1
tar xzf "sources/opus-${OPUS_VERSION}.tar.gz" -C "${WORK_DIR}/src/opus" --strip-components=1

XCFRAMEWORK_ARGS=()
for slice in ${SLICES}; do
  bash ios/build_openssl.sh "${slice}"
  bash ios/build_opus.sh "${slice}"
  bash ios/build_pjsip.sh "${slice}"
  XCFRAMEWORK_ARGS+=(
    -library "${WORK_DIR}/out/${slice}/pjsip/lib/libpjsip.a"
    -headers "${WORK_DIR}/out/${slice}/pjsip/include"
  )
done

xcodebuild -create-xcframework "${XCFRAMEWORK_ARGS[@]}" -output ./dist/ios/pjsip.xcframework

rm -rf "${WORK_DIR}"
