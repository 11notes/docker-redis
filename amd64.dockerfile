# :: Header
    FROM redis:6.2.6-alpine

# :: Run
    USER root

    RUN apk --update --no-cache add \
            shadow \
            gcc libc6-compat \
        && ln -s /lib/libc.musl-x86_64.so.1 /lib/ld-linux-x86-64.so.2 \
        && mkdir -p /redis/etc \
		&& mkdir -p /redis/var

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