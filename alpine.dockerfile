FROM alpine:3.23 AS builder

ARG VERSION=main

RUN apk update
RUN apk add --no-cache git g++ libstdc++ make pcre pcre-dev python3

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/danmar/cppcheck.git
WORKDIR /cppcheck

ADD patches /patches
RUN if [ -d "../patches/${VERSION}" ]; then git apply ../patches/${VERSION}/*.patch; fi
RUN make \
    CXXFLAGS="-O3 -DNDEBUG -w -flto=$(nproc) -pipe -DNO_UNIX_BACKTRACE_SUPPORT" \
    HAVE_RULES=yes \
    FILESDIR=/usr/share/cppcheck \
    MATCHCOMPILER=yes \
    -j $(nproc) \
    install
RUN strip /usr/bin/cppcheck
RUN mkdir -p /usr/share/cppcheck

FROM alpine:3.23

COPY --from=builder /usr/bin/cppcheck /usr/bin/cppcheck
COPY --from=builder /usr/share/cppcheck /usr/share/cppcheck

RUN apk update && \
    apk add --no-cache cmake && \
    rm -rf /var/cache/apk/*
