# :: Builder
    FROM rust:latest AS builder
    ENV MODULE_DIR=/redis/lib/modules
    ENV MODULE_DEPS="python python-setuptools pip wget unzip build-essential build-essential llvm libclang1 libclang-dev cargo cmake git"

    RUN set -ex;\
        deps="$MODULE_DEPS";\
        apt-get update -y; \
        apt-get install -y --no-install-recommends $deps;\
        pip install rmtest

    RUN set -ex;\
        git clone https://github.com/RedisJSON/RedisJSON.git /tmp/RedisJSON;\
        cd /tmp/RedisJSON;\
        cargo build --release;\
        mv target/release/librejson.so target/release/rejson.so

# :: Header
    FROM redis:6.2.6-alpine

# :: Run
    USER root

    RUN apk --update --no-cache add \
            shadow \
            gcc libc6-compat \
        && ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 \
        && mkdir -p /redis/etc \
		&& mkdir -p /redis/var \
		&& mkdir -p /redis/lib/modules

    COPY ./source/etc /redis/etc
    COPY --from=builder /tmp/RedisJSON/target/release/rejson.so /redis/lib/modules

    # :: docker -u 1000:1000 (no root initiative)
        RUN APP_UID="$(id -u redis)" \
            && APP_GID="$(id -g redis)" \
            && find / -not -path "/proc/*" -user $APP_UID -exec chown -h -R 1000:1000 {} \;\
            && find / -not -path "/proc/*" -group $APP_GID -exec chown -h -R 1000:1000 {} \;
        RUN usermod -u 1000 redis \
            && groupmod -g 1000 redis \
            && chown -R 1000:1000 /redis

    USER redis

    CMD ["redis-server", "/redis/etc/redis.conf"]