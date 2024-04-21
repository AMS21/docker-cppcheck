FROM alpine:3.19

ARG VERSION

ADD patches/ patches/

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache git g++ libstdc++ make pcre pcre-dev python3 && \
    git clone --depth 1 --branch "${VERSION}" https://github.com/danmar/cppcheck.git && \
    cd cppcheck && \
    if [ -d "../patches/${VERSION}" ]; then git apply ../patches/${VERSION}/*.patch; fi && \
    make CXXFLAGS="-O3 -DNDEBUG -w -mtune=native -flto=$(nproc)" HAVE_RULES=yes FILESDIR=/usr/share/cppcheck MATCHCOMPILER=yes -j $(nproc) install && \
    cd ../.. && \
    rm -rf cppcheck && rm -rf patches && \
    apk del --purge git g++ libstdc++-dev make pcre-dev python3 && \
    rm -rf /var/cache/apk/*
