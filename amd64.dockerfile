# :: Util
  FROM alpine as util

  RUN set -ex; \
    apk add --no-cache \
      git; \
    git clone https://github.com/11notes/util.git;

# :: Build
  FROM 11notes/alpine-build:default as build
  ENV BUILD_VERSION=7.4.0
  ENV USE_JEMALLOC=no
  ENV MALLOC=mimalloc
  ENV BUILD_TLS=yes

  COPY ./build /.build

  RUN set -ex; \
    cd /.build; \
    wget -c https://download.redis.io/releases/redis-${BUILD_VERSION}.tar.gz -O - | tar -xz; \
    mv ./make.sh ./redis-${BUILD_VERSION}/deps; \
    chmod +x ./redis-${BUILD_VERSION}/deps/make.sh; \
    cd ./redis-${BUILD_VERSION}/deps; \
    ./make.sh; \
    cd ..; \
    make all; \
    cp ./src/redis-server /.release; \
    cp ./src/redis-cli /.release; \
    cp ./redis.conf /.release;

# :: Header
  FROM 11notes/alpine:stable
  COPY --from=build /.release/ /usr/local/bin
  COPY --from=util /util/linux/shell/elevenLogJSON /usr/local/bin
  ENV APP_ROOT=/redis

# :: Run
  USER root

  # :: install application
    RUN set -ex; \
      apk --no-cache --update add \
        openssl; \
      apk --no-cache --update upgrade;

  # :: prepare image
    RUN set -ex; \
      mkdir -p ${APP_ROOT}/etc; \
      mkdir -p ${APP_ROOT}/var; \
      mkdir -p ${APP_ROOT}/ssl; \
      mkdir -p ${APP_ROOT}/run; \
      mkdir -p ${APP_ROOT}/.default; \
      mv /usr/local/bin/redis.conf ${APP_ROOT}/.default/default.conf

  # :: copy root filesystem changes and add execution rights to init scripts
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin;

  # :: change home path for existing user and set correct permission
    RUN set -ex; \
      usermod -d ${APP_ROOT} docker; \
      chown -R 1000:1000 \
        ${APP_ROOT};

# :: Volumes
	VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var", "${APP_ROOT}/ssl"]

# :: Monitor
  HEALTHCHECK CMD /usr/local/bin/healthcheck.sh || exit 1

# :: Start
	USER docker
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]