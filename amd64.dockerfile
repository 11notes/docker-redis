# :: Build
  FROM rust:latest AS build

  RUN set -ex;\
    apt update -y; apt install -y --no-install-recommends \
      python \
      python-setuptools \
      pip \
      wget \
      unzip \
      build-essential \
      llvm \
      libclang1 \
      libclang-dev \
      cargo \
      cmake \
      git; \
    pip install rmtest

  RUN set -ex;\
    git clone https://github.com/RedisJSON/RedisJSON.git /tmp/RedisJSON;\
    cd /tmp/RedisJSON;\
    cargo build --release;\
    mv target/release/librejson.so target/release/rejson.so

# :: Header
  FROM redis:7-alpine

# :: Run
  USER root

  # :: update image
    RUN set -ex; \
      apk --update --no-cache add \
        curl \
        tzdata \
        shadow; \
      apk update; \
      apk upgrade;

  # :: prepare image
    RUN set -ex; \
      mkdir -p /redis/etc; \
      mkdir -p /redis/var; \
      mkdir -p /redis/lib/modules;

    RUN set -ex; \
      apk --update --no-cache add \
        gcc \
        libc6-compat; \
      ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2;

    # :: fix CVE-2023-1972
    RUN set -ex; \
      apk --update --no-cache add \
        binutils>=2.40-r10;

  # :: copy root filesystem changes and add execution rights to init scripts
    COPY ./rootfs /
    COPY --from=build /tmp/RedisJSON/target/release/rejson.so /redis/lib/modules
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
      usermod -d /redis docker; \
      chown -R 1000:1000 \
        /redis;

# :: Volumes
	VOLUME ["/redis/etc", "/redis/var"]

# :: Start
	USER redis
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]