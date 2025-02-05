# :: Util
  FROM alpine AS util

  RUN set -ex; \
    apk --no-cache --update add \
      git; \
    git clone https://github.com/11notes/docker-util.git;

# :: Build / redis
  FROM 11notes/alpine:stable AS build

  ARG TARGETARCH
  ARG APP_VERSION
  ENV BUILD_TLS=yes
  ENV OPTIMIZATION=-O2
  ENV USE_JEMALLOC=no
  ENV MALLOC=mimalloc

  USER root

  RUN set -ex; \ 
    apk add --update --no-cache \
      git \
      coreutils \
      dpkg-dev dpkg \
      gcc \
      linux-headers \
      make \
      musl-dev \
      openssl-dev;

  RUN set -ex; \
    git clone https://github.com/redis/redis.git -b ${APP_VERSION}; \
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *1 *,.*[)],$' /redis/src/config.c; \
    sed -ri 's!^( *createBoolConfig[(]"protected-mode",.*, *)1( *,.*[)],)$!\10\2!' /redis/src/config.c; \
    grep -E '^ *createBoolConfig[(]"protected-mode",.*, *0 *,.*[)],$' /redis/src/config.c; \
    rm -rf /redis/deps/jemalloc;

  RUN set -ex; \
    make -C /redis all V=1;

  RUN set -ex; \
    cp /redis/src/redis-server /usr/local/bin; \
    cp /redis/src/redis-cli /usr/local/bin; \
    cp /redis/redis.conf /usr/local/bin;

# :: Header
  FROM 11notes/alpine:stable

  # :: arguments
    ARG TARGETARCH
    ARG APP_IMAGE
    ARG APP_NAME
    ARG APP_VERSION
    ARG APP_ROOT

  # :: environment
    ENV APP_IMAGE=${APP_IMAGE}
    ENV APP_NAME=${APP_NAME}
    ENV APP_VERSION=${APP_VERSION}
    ENV APP_ROOT=${APP_ROOT}

    ENV REDIS_CONFIG=/redis/etc/default.conf
    ENV REDIS_IP=0.0.0.0

  # :: multi-stage
    COPY --from=util /docker-util/src/ /usr/local/bin
    COPY --from=build /usr/local/bin/ /usr/local/bin

  # :: Run
  USER root

  # :: install application
    RUN set -eux; \
      apk --no-cache --update add \
        openssl;

    RUN set -eux; \
      mkdir -p ${APP_ROOT}/etc; \
      mkdir -p ${APP_ROOT}/var; \
      mkdir -p ${APP_ROOT}/ssl;

    RUN set -eux; \
      mkdir -p ${APP_ROOT}/run; \
      mkdir -p ${APP_ROOT}/.default; \
      mv /usr/local/bin/redis.conf ${APP_ROOT}/.default/default.conf; \
      redis-server --version; \
      redis-cli --version;

  # :: copy filesystem changes and set correct permissions
    COPY ./rootfs /
    RUN set -eux; \
      chmod +x -R /usr/local/bin; \
      chown -R 1000:1000 \
        ${APP_ROOT};

# :: Volumes
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var", "${APP_ROOT}/ssl"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER docker