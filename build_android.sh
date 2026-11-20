#!/bin/bash
# Builds static pjsip libraries for Android in Docker. Output: dist/android/<abi>/{lib,include}
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${ROOT_DIR}/versions.env"
cd "${ROOT_DIR}"

./fetch_sources.sh android

IMAGE_NAME="react-native-pjsip-builder/android"

rm -rf ./dist/android
mkdir -p ./dist/

# The NDK Linux toolchain is x86_64 only, so the image is always linux/amd64.
docker build \
  --platform linux/amd64 \
  --file android/Dockerfile \
  --build-arg PJSIP_VERSION="${PJSIP_VERSION}" \
  --build-arg OPENSSL_VERSION="${OPENSSL_VERSION}" \
  --build-arg OPUS_VERSION="${OPUS_VERSION}" \
  --build-arg NDK_VERSION="${NDK_VERSION}" \
  --build-arg ANDROID_API="${ANDROID_API}" \
  --build-arg ANDROID_ABIS="${ANDROID_ABIS}" \
  --tag "${IMAGE_NAME}" \
  .

CONTAINER_ID="$(docker create --platform linux/amd64 "${IMAGE_NAME}")"
docker cp "${CONTAINER_ID}:/dist/android" ./dist/android
docker rm "${CONTAINER_ID}"
