# :: QEMU
  FROM multiarch/qemu-user-static:x86_64-aarch64 as qemu

# :: Util
  FROM alpine as util

  RUN set -ex; \
    apk add --no-cache \
      git; \
    git clone https://github.com/11notes/util.git;

# :: Build
  FROM 11notes/alpine-build:arm64v8-default as build
  COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin
  ENV VERSION=6.2.14
  ENV USE_JEMALLOC=no
  ENV MALLOC=mimalloc
  ENV BUILD_TLS=yes

  COPY ./build /.build

  RUN set -ex; \
    cd /.build; \
    wget -c https://download.redis.io/releases/redis-${VERSION}.tar.gz -O - | tar -xz; \
    mv ./make.sh ./redis-${VERSION}/deps; \
    chmod +x ./redis-${VERSION}/deps/make.sh; \
    cd ./redis-${VERSION}/deps; \
    ./make.sh; \
    cd ..; \
    make all; \
    cp ./src/redis-server /.src; \
    cp ./src/redis-cli /.src; \
    cp ./src/redis-benchmark /.src; \
    cp ./redis.conf /.src;

# :: Header
  FROM 11notes/alpine:arm64v8-stable
  COPY --from=qemu /usr/bin/qemu-aarch64-static /usr/bin
  COPY --from=build /.src/ /usr/local/bin
  COPY --from=util /util/linux/shell/elevenLogJSON /usr/local/bin
  ENV APP_ROOT=/redis

# :: Run
  USER root

  # :: install application
    RUN set -ex; \
      apk --no-cache add \
        openssl; \
      apk --no-cache upgrade;

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