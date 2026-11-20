#!/bin/bash
# Downloads the source archives a build needs into ./sources and verifies each
# one against checksums.sha256. A missing or mismatching checksum fails the build.
#
# Usage:
#   ./fetch_sources.sh [android|ios|all]
#   ./fetch_sources.sh --pin [android|ios|all]
#
# --pin records checksums for archives that have no entry yet. Use it only after
# a version bump, and compare the recorded value with the checksum published
# upstream before committing checksums.sha256.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${ROOT_DIR}/versions.env"

SOURCES_DIR="${ROOT_DIR}/sources"
CHECKSUMS_FILE="${ROOT_DIR}/checksums.sha256"

PIN=false
if [ "${1:-}" == "--pin" ]; then
  PIN=true
  shift
fi
PLATFORM="${1:-all}"

case "${PLATFORM}" in
  android|ios|all) ;;
  *)
    echo "Usage: $0 [--pin] [android|ios|all]" >&2
    exit 1
    ;;
esac

sha256() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

fetch() {
  local file="$1"
  local url="$2"
  local path="${SOURCES_DIR}/${file}"

  if [ ! -f "${path}" ]; then
    echo "Downloading ${file}"
    curl --fail --location --proto '=https' --tlsv1.2 --silent --show-error -o "${path}.part" "${url}"
    mv "${path}.part" "${path}"
  fi

  local actual expected
  actual="$(sha256 "${path}")"
  expected="$(awk -v f="${file}" '$2 == f {print $1}' "${CHECKSUMS_FILE}" 2> /dev/null || true)"

  if [ -z "${expected}" ]; then
    if [ "${PIN}" = true ]; then
      echo "${actual}  ${file}" >> "${CHECKSUMS_FILE}"
      echo "Pinned ${file}: ${actual}"
      return
    fi
    echo "ERROR: ${file} has no entry in checksums.sha256 (actual: ${actual})." >&2
    echo "Compare it with the upstream published checksum, then run: $0 --pin ${PLATFORM}" >&2
    exit 1
  fi

  if [ "${actual}" != "${expected}" ]; then
    echo "ERROR: checksum mismatch for ${file}: expected ${expected}, got ${actual}" >&2
    exit 1
  fi

  echo "Verified ${file}"
}

mkdir -p "${SOURCES_DIR}"

fetch "pjproject-${PJSIP_VERSION}.tar.gz" \
  "https://github.com/pjsip/pjproject/archive/refs/tags/${PJSIP_VERSION}.tar.gz"
fetch "openssl-${OPENSSL_VERSION}.tar.gz" \
  "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz"
fetch "opus-${OPUS_VERSION}.tar.gz" \
  "https://downloads.xiph.org/releases/opus/opus-${OPUS_VERSION}.tar.gz"

if [ "${PLATFORM}" != "ios" ]; then
  fetch "android-ndk-${NDK_VERSION}-linux.zip" \
    "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip"
fi
