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
  FROM redis:6-alpine
  COPY --from=build /tmp/RedisJSON/target/release/rejson.so /redis/lib/modules

# :: Run
  USER root

  # :: prepare
    RUN set -ex; \
      mkdir -p /redis/etc; \
      mkdir -p /redis/var; \
      mkdir -p /redis/lib/modules;

    RUN set -ex; \
      apk --update --no-cache add \
        shadow \
        gcc \
        libc6-compat; \
      ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2;

  # :: copy root filesystem changes
    COPY ./rootfs /
    RUN set -ex; \
      chmod +x -R /usr/local/bin

  # :: docker -u 1000:1000 (no root initiative)
    RUN set -ex; \
      DOCKER_USER="redis" \
      DOCKER_UID="$(id -u ${DOCKER_USER})"; \
      DOCKER_GID="$(id -g ${DOCKER_USER})"; \
      find / -not -path "/proc/*" -user ${$DOCKER_UID} -exec chown -h -R 1000:1000 {} \;;\
      find / -not -path "/proc/*" -group ${$DOCKER_GID} -exec chown -h -R 1000:1000 {} \;;
    
    RUN set -ex; \
      usermod -u 1000 redis; \
      groupmod -g 1000 redis; \
      chown -R 1000:1000 \
        /redis;

# :: Volumes
	VOLUME ["/redis/etc", "/redis/var"]

# :: Start
	USER redis
	ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]