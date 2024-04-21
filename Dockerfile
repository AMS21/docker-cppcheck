FROM alpine:3.19

ARG VERSION

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache cmake git g++ libstdc++ make pcre pcre-dev python3 && \
    git clone --depth 1 --branch "${VERSION}" https://github.com/danmar/cppcheck.git && \
    cd cppcheck && \
    if [ -d "../patches/${VERSION}" ]; then git apply ../patches/${VERSION}/*.patch; fi && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE:STRING="Release" -DUSE_MATCHCOMPILER:BOOL=On -DHAVE_RULES:BOOL=ON -DCMAKE_CXX_FLAGS:STRING="-O3 -DNDEBUG -w -mtune=native" && \
    make -j $(nproc) && \
    make install && \
    cd ../.. && \
    rm -rf cppcheck && rm -rf patches && \
    apk del --purge cmake git g++ make pcre-dev python3 && \
    rm -rf /var/cache/apk/*
