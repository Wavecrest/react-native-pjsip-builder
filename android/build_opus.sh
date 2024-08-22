#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/opus/${TARGET_ARCH}

cp -r /sources/opus /tmp/opus

cd /tmp/opus/jni

# Valid APP_ABI values: armeabi-v7a, arm64-v8a, x86_64
if [[ "$TARGET_ARCH" == "armeabi-v7a" || "$TARGET_ARCH" == "arm64-v8a" || "$TARGET_ARCH" == "x86_64" ]]; then
    APP_ABI="${TARGET_ARCH}"
else
    echo "Invalid architecture: $TARGET_ARCH"
    exit 1
fi

# Run ndk-build with the appropriate APP_ABI
ndk-build APP_ABI="${APP_ABI}"

mkdir -p ${TARGET_PATH}/include
mkdir -p ${TARGET_PATH}/lib

cp -r ../include ${TARGET_PATH}/include/opus
cp ../obj/local/${APP_ABI}/libopus.a ${TARGET_PATH}/lib/

# Clean up temporary directory
rm -rf /tmp/opus
