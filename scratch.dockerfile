FROM alpine:3.23 AS builder

ARG VERSION=main

RUN apk update
RUN apk add --no-cache git g++ libstdc++ make pcre pcre-dev pcre-static python3

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/danmar/cppcheck.git
WORKDIR /cppcheck

ADD patches /patches
RUN if [ -d "../patches/${VERSION}" ]; then git apply ../patches/${VERSION}/*.patch; fi
RUN make \
    CXXFLAGS="-O3 -DNDEBUG -w -flto=$(nproc) -pipe -DNO_UNIX_BACKTRACE_SUPPORT -static -static-libgcc -static-libstdc++" \
    LDFLAGS="-static -static-libgcc -static-libstdc++" \
    HAVE_RULES=yes \
    FILESDIR=/config \
    MATCHCOMPILER=yes \
    -j $(nproc) \
    install
RUN strip /usr/bin/cppcheck
RUN mkdir -p /config

FROM scratch

COPY --from=builder /usr/bin/cppcheck /
COPY --from=builder /config /config

ENTRYPOINT [ "/cppcheck" ]
