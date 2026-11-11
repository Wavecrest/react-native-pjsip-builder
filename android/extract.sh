# Create a stopped container from the image
CID=$(docker create pjsip-android:latest)

# Copy the build results out
docker cp "$CID":/dist/android/src/main ./android-dist
#docker cp "$CID":/sources/android_ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so ./android-dist/main/jniLibs/arm64-v8a/
#docker cp "$CID":/sources/android_ndk/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/arm-linux-androideabi/libc++_shared.so ./android-dist/main/jniLibs/armeabi-v7a/

# Remove the temporary container
docker rm "$CID"

