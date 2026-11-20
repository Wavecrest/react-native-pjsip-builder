# react-native-pjsip-builder
Builds static PJSIP libraries with OpenSSL and Opus for Android and iOS, from the same pinned sources on both platforms.

## Versions
All versions are pinned in [`versions.env`](versions.env).

| Component    | Version              |
|--------------|----------------------|
| PJSIP        | 2.17                 |
| OpenSSL      | 3.5.9                |
| Opus         | 1.5.2                |
| Android NDK  | r27b (27.1.12297006) |
| Android API  | 29 (minSdk)          |
| Android ABIs | arm64-v8a, armeabi-v7a |
| iOS minimum  | 15.1                 |
| iOS slices   | device arm64, simulator arm64 |

`NDK_VERSION`, `ANDROID_API` and `IOS_MIN_VERSION` must stay in line with the app that links these libraries.

## Sources
`fetch_sources.sh` downloads every source archive into `sources/` and verifies it against `checksums.sha256`. Both build scripts call it, so the builds never use unverified sources.

After changing a version in `versions.env`:
```
./fetch_sources.sh --pin
```
Compare each recorded checksum with the one published upstream, then commit `checksums.sha256`.

## Build for Android
Requires Docker. Runs as `linux/amd64` because the NDK Linux toolchain is x86_64 only.
```
./build_android.sh
```
Output: `dist/android/<abi>/lib/libpjsip.a` and `dist/android/<abi>/include/`.

## Build for iOS
Requires macOS with Xcode (iOS toolchains do not run in Docker).
```
./build_ios.sh
```
Output: `dist/ios/pjsip.xcframework`.

## Release
```
./release.sh
```
Packages `release/<RELEASE_VERSION>/`:
- `pjsip-android.tar.gz`
- `pjsip-ios.tar.gz`
- `manifest.json`: component versions and build targets
- `SHA256SUMS`

Upload all four files to a GitHub release tagged `<RELEASE_VERSION>`.

`libpjsip.a` is one static archive with pjproject (including third_party), OpenSSL and Opus merged in. It contains the pjsua2 C++ API, so the consuming build must use the same NDK (Android) and compile with exceptions and RTTI enabled.
