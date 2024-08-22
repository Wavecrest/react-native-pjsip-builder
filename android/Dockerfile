FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/New_York

##############################
# Download dependencies
##############################

RUN apt-get update --fix-missing && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade

RUN apt-get update && \
    apt-get -y install tzdata software-properties-common git curl bzip2 gcc g++ binutils make autoconf openssl \
    libssl-dev ant libopus0 libpcre3 libpcre3-dev build-essential nasm \
    openjdk-8-jdk unzip && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

##############################
# Configuration
##############################

# ENV TARGET_ARCHS "armeabi armeabi-v7a x86 mips arm64-v8a x86_64 mips64"
ENV TARGET_ARCHS "armeabi-v7a arm64-v8a x86_64"
ENV ANDROID_NDK_DOWNLOAD_URL "https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip"
ENV ANDROID_SDK_DOWNLOAD_URL "https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip"
ENV ANDROID_SETUP_APIS "29 34"
ENV ANDROID_BUILD_TOOLS_VERSION '34.0.0'
ENV ANDROID_TARGET_API 29

ENV PJSIP_DOWNLOAD_URL "https://github.com/pjsip/pjproject/archive/refs/tags/2.9.tar.gz"

ENV SWIG_DOWNLOAD_URL "http://prdownloads.sourceforge.net/swig/swig-3.0.7.tar.gz"

ENV OPENSSL_DOWNLOAD_URL "https://www.openssl.org/source/openssl-1.0.2g.tar.gz"

#ENV OPENH264_DOWNLOAD_URL "https://github.com/cisco/openh264/archive/v1.7.0.tar.gz"
#ENV OPENH264_TARGET_NDK_LEVEL 29

ENV OPUS_DOWNLOAD_URL "http://downloads.xiph.org/releases/opus/opus-1.2.1.tar.gz"
ENV OPUS_ANDROID_MK_DOWNLOAD_URL "https://trac.pjsip.org/repos/raw-attachment/ticket/1904/Android.mk"

ENV PATH /sources/android_ndk:$PATH

##############################
# Download sources
##############################

RUN mkdir -p /sources/android_ndk && \
    mkdir -p /sources/android_sdk && \
    mkdir -p /sources/pjsip && \
    mkdir -p /sources/swig && \
    mkdir -p /sources/openssl && \
    mkdir -p /sources/opus && \
    mkdir -p /sources/openh264

# Download Android NDK
RUN cd /sources/android_ndk && \
    curl -L -# -o ndk.zip "$ANDROID_NDK_DOWNLOAD_URL" && \
    unzip ndk.zip && \
    rm -rf ndk.zip && \
    mv android-*/* ./

# Download Android SDK & APIs
RUN cd /sources/android_sdk && \
    curl -L -# -o sdk.zip "$ANDROID_SDK_DOWNLOAD_URL" && \
    unzip sdk.zip

RUN mkdir -p /sources/android_sdk/cmdline-tools/latest && \
    find /sources/android_sdk/cmdline-tools/ -mindepth 1 -maxdepth 1 ! -name latest -exec cp -r {} /sources/android_sdk/cmdline-tools/latest/ \; && \
    cd /sources/android_sdk/cmdline-tools/latest/bin && \
    IFS=" " && \
    for api in $ANDROID_SETUP_APIS; do \
      yes | ./sdkmanager "platforms;android-${api}" "build-tools;${ANDROID_BUILD_TOOLS_VERSION}"; \
    done && \
    yes | ./sdkmanager "platform-tools"

# Download Pjsip
RUN cd /sources/pjsip && \
    curl -L -# -o pjsip.tar.gz "$PJSIP_DOWNLOAD_URL" && \
    tar xzf pjsip.tar.gz && \
    rm -rf pjsip.tar.gz && \
    mv pjproject-*/* ./

# Download Swig
RUN cd /sources/swig && \
    curl -L -# -o swig.tar.gz "$SWIG_DOWNLOAD_URL" && \
    tar xzf swig.tar.gz && \
    rm -rf swig.tar.gz && \
    mv swig-*/* ./

# Download OpenSSL
RUN cd /sources/openssl && \
    curl -L -# -o openssl.tar.gz "$OPENSSL_DOWNLOAD_URL" && \
    tar xzf openssl.tar.gz && \
    rm -rf openssl.tar.gz && \
    mv openssl-*/* ./

# Download Opus
RUN cd /sources/opus && \
    curl -k -L -# -o opus.tar.gz "$OPUS_DOWNLOAD_URL" && \
    tar xzf opus.tar.gz && \
    rm -rf opus.tar.gz && \
    mv opus-*/* ./ && \
    mkdir ./jni && \
    cd ./jni && \
    curl -k -L -# -o Android.mk "$OPUS_ANDROID_MK_DOWNLOAD_URL"

# Download OpenH264
#RUN cd /sources/openh264 && \
#    curl -L -# -o openh264.tar.gz "$OPENH264_DOWNLOAD_URL" && \
#    tar xzf openh264.tar.gz && \
#    rm -rf openh264.tar.gz && \
#    mv openh264-*/* ./

##############################
# Build swig, openssl, opus, openh264
##############################

RUN mkdir -p /output/openssl/ && \
    mkdir -p /output/openh264/ && \
    mkdir -p /output/pjsip && \
    mkdir -p /output/opus

# Build opus
ADD ./build_opus.sh /usr/local/sbin/
RUN IFS=" " && \
    for arch in $TARGET_ARCHS; \
    do \
      build_opus.sh ${arch}; \
    done

# Build swig
RUN cd /sources/swig && \
    ./configure && \
    make && \
    make install

# Build OpenH264
#ADD ./build_openh264.sh /usr/local/sbin/
#RUN IFS=" " && \
#    for arch in $TARGET_ARCHS; \
#    do \
#      build_openh264.sh ${arch}; \
#    done

# Build openssl
ADD ./build_openssl.sh /usr/local/sbin/
RUN IFS=" " && \
    for arch in $TARGET_ARCHS; \
    do \
      build_openssl.sh ${arch}; \
    done

# Build pjsip
ADD ./build_pjsip.sh /usr/local/sbin/
RUN IFS=" " && \
    for arch in $TARGET_ARCHS; \
    do \
      build_pjsip.sh ${arch}; \
    done

# Dist
RUN mkdir -p /dist/android/src/main && \
    mv /output/pjsip/* /dist/android/src/main && \
    rm -rf /dist/android/src/main/java/org/pjsip/pjsua2/app

#RUN IFS=" " && \
#    for arch in $TARGET_ARCHS; \
#    do \
#      mv /output/openh264/${arch}/lib/libopenh264.so /dist/android/src/main/jniLibs/${arch}/; \
#    done

