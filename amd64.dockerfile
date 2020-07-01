# :: Builder
    FROM rust:latest AS builder
    ENV MODULE_DIR=/redis/lib/modules
    ENV MODULE_DEPS="python python-setuptools python-pip wget unzip build-essential clang-6.0 cmake"

    RUN set -ex;\
        deps="$MODULE_DEPS";\
        apt-get update; \
        apt-get install -y --no-install-recommends $deps;\
        pip install rmtest

    ADD . /REJSON
    WORKDIR /REJSON
    RUN set -ex;\
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

    COPY --from=builder /REJSON/target/release/rejson.so /redis/lib/modules/rejson.so

    # :: docker -u 1000:1000 (no root initiative)   
        RUN usermod -u 1000 redis \
            && groupmod -g 1000 redis \
            && chown -R 1000:1000 /redis

    USER redis

    CMD ["redis-server", "--loadmodule", "/redis/lib/modules/rejson.so", "dir", "/redis/var"]