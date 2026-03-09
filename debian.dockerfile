FROM debian:stable-slim AS builder

ARG VERSION=main

RUN apt update
RUN apt install --no-install-recommends -y git g++ make python3 python-is-python3 ca-certificates wget bzip2

# Build PCRE from source since debian now only supports PCRE2, which is not compatible with cppcheck
RUN wget -q https://unlimited.dl.sourceforge.net/project/pcre/pcre/8.45/pcre-8.45.tar.bz2?viasf=1 -O pcre-8.45.tar.bz2
RUN tar xjf pcre-8.45.tar.bz2
WORKDIR /pcre-8.45
RUN ./configure \
    CFLAGS="-O3 -DNDEBUG -w -flto=$(nproc) -pipe" \
    --prefix=/usr \
    --disable-shared \
    --enable-static \
    --disable-cpp \
    --disable-pcregrep-libz \
    --disable-pcregrep-libbz2 \
    --disable-pcretest-libreadline
RUN make -j$(nproc) install
WORKDIR /

# Build cppcheck
RUN git clone --depth 1 --branch "${VERSION}" https://github.com/danmar/cppcheck.git
WORKDIR /cppcheck

ADD patches /patches
RUN if [ -d "../patches/${VERSION}" ]; then git apply ../patches/${VERSION}/*.patch; fi
RUN make \
    CXXFLAGS="-O3 -DNDEBUG -w -flto=$(nproc) -pipe" \
    HAVE_RULES=yes \
    FILESDIR=/usr/share/cppcheck \
    MATCHCOMPILER=yes \
    -j $(nproc) \
    install
RUN strip /usr/bin/cppcheck
RUN mkdir -p /usr/share/cppcheck

# -- Final image

FROM debian:stable-slim

COPY --from=builder /usr/bin/cppcheck /usr/bin/cppcheck
COPY --from=builder /usr/share/cppcheck /usr/share/cppcheck

RUN apt update && \
    apt install -y --no-install-recommends cmake && \
    rm -rf /var/lib/apt/lists/*
