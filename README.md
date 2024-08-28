# react-native-pjsip-builder
Easily build PJSIP with: OpenSSL, OpenH264, Opus and G.729 for Android and iOS, by using Docker and xCode.

## Versions
| Library      | Version   |
|--------------|-----------|
| Android API  | 29        |
| Android NDK  | r21e      |
| PJSIP        | 2.9.0     |
| OPENSSL      | 1.0.2g    |
| ~~OPENH264~~ | ~~1.7.0~~ | 
| OPUS         | 1.2.1 (?) |

## Build for Android
```
git clone https://github.com/datso/react-native-pjsip-builder
cd react-native-pjsip-builder; ./build_android
```

```
docker buildx build \
--platform linux/arm64,linux/amd64 \
--tag yourtag \
--cache-from=type=local,src=./cache \
--cache-to=type=local,dest=./cache,mode=max \
--push .
```

## Build for iOS
```
TODO: Will be available soon.
```
