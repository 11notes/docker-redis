# :: Util
  FROM alpine AS util

  RUN set -ex; \
    apk --no-cache --update add \
      git; \
    git clone https://github.com/11notes/docker-util.git;

# :: Build / redis
  FROM 11notes/alpine:stable AS build
  ARG APP_VERSION
  ENV USE_JEMALLOC=no
  ENV MALLOC=mimalloc
  ENV BUILD_TLS=yes

  USER root

  RUN set -ex; \
    apk add --update --no-cache \
      curl \
      wget \
      tar \
      lz4 \
      xz \
      unzip \
      build-base \
      linux-headers \
      openssl-dev \
      make \
      cmake \
      gcc \
      g++ \
      git; \
    mkdir -p /build; \
    mkdir -p /release;

  RUN set -ex; \
    cd /build; \
    wget -c https://download.redis.io/releases/redis-${APP_VERSION}.tar.gz -O - | tar -xz; \
    cd ./redis-${APP_VERSION}/deps; \
    for DEP in */; do DEP=$(echo $DEP | sed -E 's#\/##'); if ! echo "$DEP" | grep -q 'jemalloc'; then make $DEP; fi; done; \
    cd ..; \
    make all; \
    cp ./src/redis-server /release; \
    cp ./src/redis-cli /release; \
    cp ./redis.conf /release;

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
    COPY --from=build /release/ /usr/local/bin

  # :: Run
  USER root

  # :: install application
    RUN set -ex; \
      apk --no-cache --update add \
        openssl;

    RUN set -ex; \
      mkdir -p ${APP_ROOT}/etc; \
      mkdir -p ${APP_ROOT}/var; \
      mkdir -p ${APP_ROOT}/ssl;

    RUN set -ex; \
      mkdir -p ${APP_ROOT}/run; \
      mkdir -p ${APP_ROOT}/.default; \
      mv /usr/local/bin/redis.conf ${APP_ROOT}/.default/default.conf

  # :: copy filesystem changes and set correct permissions
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin; \
      chown -R 1000:1000 \
        ${APP_ROOT};

# :: Volumes
  VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var", "${APP_ROOT}/ssl"]

# :: Monitor
  HEALTHCHECK --interval=5s --timeout=2s CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
  USER docker