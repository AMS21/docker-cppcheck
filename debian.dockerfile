FROM debian:stable-slim AS builder

ARG VERSION=main

RUN apt-get update && \
    apt install --no-install-recommends -y git g++ make python3 ca-certificates wget bzip2 && \
    rm -rf /var/lib/apt/lists/*

# Build PCRE from source since debian now only supports PCRE2, which is not compatible with cppcheck
RUN wget -q https://unlimited.dl.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.bz2?viasf=1 -O pcre-8.45.tar.bz2 && \
    tar xjf pcre-8.45.tar.bz2 && \
    cd pcre-8.45 && \
    ./configure \
    CFLAGS="-O3 -DNDEBUG -w -flto=$(nproc) -pipe" \
    --prefix=/usr \
    --disable-shared \
    --enable-static \
    --disable-cpp \
    --disable-pcregrep-libz \
    --disable-pcregrep-libbz2 \
    --disable-pcretest-libreadline && \
    make -j$(nproc) install

ADD patches/ patches/

# Build cppcheck
RUN git clone --depth 1 --branch "${VERSION}" https://github.com/danmar/cppcheck.git && \
    cd cppcheck && \
    if [[ -d "../patches/${VERSION}" ]]; then git apply ../patches/${VERSION}/*.patch; fi && \
    make CXXFLAGS="-O3 -DNDEBUG -w -flto=$(nproc) -pipe" HAVE_RULES=yes FILESDIR=/usr/share/cppcheck MATCHCOMPILER=yes -j $(nproc) install && \
    strip /usr/bin/cppcheck

# -- Final image

FROM debian:stable-slim

COPY --from=builder /usr/bin/cppcheck /usr/bin/cppcheck
COPY --from=builder /usr/share/cppcheck /usr/share/cppcheck

RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake && \
    rm -rf /var/lib/apt/lists/*
