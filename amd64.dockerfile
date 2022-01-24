# :: Header
    FROM redis:6.2.6-alpine

# :: Run
    USER root

    RUN apk --update --no-cache add \
            shadow \
        && mkdir -p /redis/etc \
		&& mkdir -p /redis/var

    COPY ./source/etc /redis/etc

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