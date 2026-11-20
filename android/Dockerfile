# Build context is the repository root (see build_android.sh).
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install --no-install-recommends build-essential make perl unzip file ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ARG PJSIP_VERSION
ARG OPENSSL_VERSION
ARG OPUS_VERSION
ARG NDK_VERSION
ARG ANDROID_API
ARG ANDROID_ABIS

ENV ANDROID_NDK_ROOT=/sources/android_ndk
ENV ANDROID_API=${ANDROID_API}

##############################
# Unpack sources (downloaded and checksum-verified on the host by fetch_sources.sh)
##############################

COPY sources/android-ndk-${NDK_VERSION}-linux.zip \
     sources/pjproject-${PJSIP_VERSION}.tar.gz \
     sources/openssl-${OPENSSL_VERSION}.tar.gz \
     sources/opus-${OPUS_VERSION}.tar.gz \
     /archives/

RUN mkdir -p /sources/pjsip /sources/openssl /sources/opus && \
    cd /sources && \
    unzip -q /archives/android-ndk-${NDK_VERSION}-linux.zip && \
    mv android-ndk-${NDK_VERSION} android_ndk && \
    tar xzf /archives/pjproject-${PJSIP_VERSION}.tar.gz -C /sources/pjsip --strip-components=1 && \
    tar xzf /archives/openssl-${OPENSSL_VERSION}.tar.gz -C /sources/openssl --strip-components=1 && \
    tar xzf /archives/opus-${OPUS_VERSION}.tar.gz -C /sources/opus --strip-components=1 && \
    rm -rf /archives

##############################
# Build openssl, opus, pjsip per ABI
##############################

COPY android/build_openssl.sh android/build_opus.sh android/build_pjsip.sh /build/
COPY android/config_site.h /sources/config_site.h

RUN for abi in ${ANDROID_ABIS}; do \
      bash /build/build_openssl.sh "${abi}" && \
      bash /build/build_opus.sh "${abi}" && \
      bash /build/build_pjsip.sh "${abi}" || exit 1; \
    done
