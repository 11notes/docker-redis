# :: Builder
    FROM rust:latest AS builder
    ENV MODULE_DIR=/redis/lib/modules
    ENV MODULE_DEPS="python python-setuptools python-pip wget unzip build-essential clang-6.0 cmake git"

    RUN set -ex;\
        deps="$MODULE_DEPS";\
        apt-get update -y; \
        apt-get install -y --no-install-recommends $deps;\
        pip install rmtest

    RUN set -ex;\
        git clone https://github.com/RedisJSON/RedisJSON.git /tmp;\
        cd /tmp/RedisJSON;\
        cargo build --release;\
        mv target/release/librejson.so target/release/rejson.so

# :: Header
    FROM redis:6.0-alpine

# :: Run
    USER root

    RUN apk --update --no-cache add shadow \
		mkdir -p /redis/var \
		mkdir -p /redis/lib/modules \
		rm -rf /data

    COPY --from=builder /tmp/RedisJSON/target/release/rejson.so /redis/lib/modules/rejson.so

    # :: docker -u 1000:1000 (no root initiative)   
        RUN usermod -u 1000 redis \
            && groupmod -g 1000 redis \
            && chown -R 1000:1000 /redis

    USER redis

    CMD ["redis-server", "--loadmodule", "/redis/lib/modules/rejson.so", "dir", "/redis/var"]