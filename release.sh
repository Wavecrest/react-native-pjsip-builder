#!/bin/bash
# Packages dist/ into release/<RELEASE_VERSION>/ as per-platform archives plus
# manifest.json and SHA256SUMS. Run build_android.sh and build_ios.sh first.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${ROOT_DIR}/versions.env"
cd "${ROOT_DIR}"

for platform in android ios; do
  if [ ! -d "dist/${platform}" ]; then
    echo "ERROR: dist/${platform} is missing, run ./build_${platform}.sh first" >&2
    exit 1
  fi
done

OUTPUT_DIR="release/${RELEASE_VERSION}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

# COPYFILE_DISABLE stops macOS tar from adding ._* metadata files
COPYFILE_DISABLE=1 tar -czf "${OUTPUT_DIR}/pjsip-android.tar.gz" -C dist android
COPYFILE_DISABLE=1 tar -czf "${OUTPUT_DIR}/pjsip-ios.tar.gz" -C dist ios

ABIS_JSON="$(printf '"%s", ' ${ANDROID_ABIS})"
cat > "${OUTPUT_DIR}/manifest.json" <<JSON
{
  "release": "${RELEASE_VERSION}",
  "pjproject": "${PJSIP_VERSION}",
  "openssl": "${OPENSSL_VERSION}",
  "opus": "${OPUS_VERSION}",
  "android": {
    "ndk": "${NDK_VERSION}",
    "api": ${ANDROID_API},
    "abis": [${ABIS_JSON%, }]
  },
  "ios": {
    "minVersion": "${IOS_MIN_VERSION}",
    "slices": ["ios-arm64", "ios-arm64-simulator"]
  }
}
JSON

(cd "${OUTPUT_DIR}" && shasum -a 256 pjsip-android.tar.gz pjsip-ios.tar.gz manifest.json > SHA256SUMS)

echo "Release ${RELEASE_VERSION} packaged in ${OUTPUT_DIR}:"
cat "${OUTPUT_DIR}/SHA256SUMS"
