# :: Build
  FROM rust:latest AS build

  RUN set -ex;\
    apt update -y; apt install -y --no-install-recommends \
      pip \
      wget \
      unzip \
      build-essential \
      llvm \
      libclang1 \
      libclang-dev \
      cargo \
      cmake \
      git;

  RUN set -ex;\
    git clone https://github.com/RedisJSON/RedisJSON.git; \
    cd /RedisJSON;\
    cargo build --release;\
    mv target/release/librejson.so target/release/rejson.so

# :: Header
  FROM redis:7.0.14-alpine
  ENV APP_ROOT=/redis

# :: Run
  USER root

  # :: update image
    RUN set -ex; \
      apk --no-cache add \
        openssl \
        curl \
        tzdata \
        shadow; \
      apk --no-cache upgrade;

  # :: prepare image
    RUN set -ex; \
      mkdir -p ${APP_ROOT}/etc; \
      mkdir -p ${APP_ROOT}/var; \
      mkdir -p ${APP_ROOT}/ssl; \
      mkdir -p ${APP_ROOT}/lib/modules;

    RUN set -ex; \
      apk --no-cache add \
        gcc \
        libc6-compat; \
      ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2;

    # :: fix CVE-2023-1972
    RUN set -ex; \
      apk --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main add \
        binutils>2.40-r10

  # :: copy root filesystem changes and add execution rights to init scripts
    COPY ./rootfs /
    COPY --from=build /RedisJSON/target/release/rejson.so ${APP_ROOT}/lib/modules
    RUN set -ex; \
      chmod +x -R /usr/local/bin;

  # :: set uid/gid to 1000:1000 for existing user
    RUN set -ex; \
      NOROOT_USER="redis" \
      NOROOT_UID="$(id -u ${NOROOT_USER})"; \
      NOROOT_GID="$(id -g ${NOROOT_USER})"; \
      find / -not -path "/proc/*" -user ${NOROOT_UID} -exec chown -h -R 1000:1000 {} \;;\
      find / -not -path "/proc/*" -group ${NOROOT_GID} -exec chown -h -R 1000:1000 {} \;; \
      usermod -l docker ${NOROOT_USER}; \
      groupmod -n docker ${NOROOT_USER}; \
      usermod -u 1000 docker; \
      groupmod -g 1000 docker;

  # :: change home path for existing user and set correct permission
    RUN set -ex; \
      usermod -d ${APP_ROOT} docker; \
      chown -R 1000:1000 \
        ${APP_ROOT} \
        /var/redis;

# :: Volumes
	VOLUME ["${APP_ROOT}/etc", "${APP_ROOT}/var","${APP_ROOT}/ssl"]

# :: Start
	USER docker
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]