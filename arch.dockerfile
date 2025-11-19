# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
  # GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=redis/redis.git \
      BUILD_ROOT=/redis
  ARG BUILD_BIN=${BUILD_ROOT}/src/redis-server

  # :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/util:bin AS util-bin

  
# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: REDIS
  FROM alpine AS build
  COPY --from=util-bin / /
  ARG TARGETARCH \
      TARGETVARIANT \
      APP_VERSION \
      APP_ROOT \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN \
      BUILD_TLS=yes \
      OPTIMIZATION=-O2 \
      USE_JEMALLOC=yes

  RUN set -ex; \ 
    apk add --update --no-cache \
      git \
      coreutils \
      dpkg-dev dpkg \
      g++ \
      linux-headers \
      make \
      musl-dev \
      openssl-dev \
      openssl-libs-static \
      jemalloc-dev \
      libstdc++-dev \
      xxhash-dev \
      tcl \
      procps;

  RUN set -ex; \
    eleven git clone ${BUILD_SRC} ${APP_VERSION};

  RUN set -ex; \
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' ${BUILD_ROOT}/src/config.c; \
    sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' ${BUILD_ROOT}/src/config.c; \
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' ${BUILD_ROOT}/src/config.c; \
    sed -i 's|$(REDIS_SERVER_NAME) $(REDIS_SENTINEL_NAME) $(REDIS_CLI_NAME) $(REDIS_BENCHMARK_NAME) $(REDIS_CHECK_RDB_NAME) $(REDIS_CHECK_AOF_NAME) $(TLS_MODULE) module_tests|$(REDIS_SERVER_NAME) $(REDIS_CLI_NAME) $(TLS_MODULE)|' ${BUILD_ROOT}/src/Makefile;

  RUN set -ex; \
    if [ -d "${BUILD_ROOT}/deps/fast_float" ]; then \
      cd ${BUILD_ROOT}/deps/fast_float; \
      make -s -j $(nproc) \
        LDFLAGS="--static"; \
    fi;

  RUN set -ex; \
    if [ -d "${BUILD_ROOT}/deps/xxhash" ]; then \
      cd ${BUILD_ROOT}/deps/xxhash; \
      sed -i 's|lib: libxxhash.a libxxhash|lib: libxxhash.a|g' Makefile; \
      make lib -s -j $(nproc); \
    fi;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    make -s -j $(nproc) \
      CFLAGS="${CFLAGS} -fPIC -static -static-libgcc -static-libstdc++" \
      LDFLAGS="--static";

  RUN set -ex; \
    eleven distroless ${BUILD_BIN}; \
    eleven distroless ${BUILD_ROOT}/src/redis-cli; \
    mkdir -p /distroless${APP_ROOT}/etc; \
    cp ${BUILD_ROOT}/redis.conf /distroless${APP_ROOT}/etc;

  RUN set -ex; \
    eleven mkdir /distroless${APP_ROOT}/{etc,var}; \
    sed -i 's/^# requirepass.*/requirepass \$REDIS_PASSWORD/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^# masterauth.*/masterauth \$REDIS_PASSWORD/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's@^pidfile.*@pidfile /run/redis.pid@' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's@^dir.*@dir '${APP_ROOT}'/var@' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^protected-mode.*/protected-mode no/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^bind.*/bind \$REDIS_IP/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^port.*/port \$REDIS_PORT/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^appendonly.*/appendonly yes/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^# save 3600.*/save 3600 1 300 100 60 10000/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^# shutdown-on-sigint.*/shutdown-on-sigint save/' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i 's/^# shutdown-on-sigterm.*/shutdown-on-sigterm save/' /distroless${APP_ROOT}/etc/redis.conf;

  RUN set -ex; \
    sed -i 's/^#.*//' /distroless${APP_ROOT}/etc/redis.conf; \
    sed -i '/^$/d' /distroless${APP_ROOT}/etc/redis.conf;

  # INIT
  FROM 11notes/go:1.25 AS init
  COPY ./build /
  ARG APP_VERSION \
      BUILD_ROOT=/go/redis
  ARG BUILD_BIN=${BUILD_ROOT}/redis

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    eleven go build ${BUILD_BIN} main.go; \
    eleven distroless ${BUILD_BIN};


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
  # :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific defaults
    ENV REDISCLI_HISTFILE=/dev/null \
        REDIS_IP=0.0.0.0 \
        REDIS_PORT=6379

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=build --chown=${APP_UID}:${APP_GID} /distroless/ /
    COPY --from=init /distroless/ /

# :: HEALTH
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/redis-cli", "ping"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/redis"]