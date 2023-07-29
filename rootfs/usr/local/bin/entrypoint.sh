#!/bin/ash
  if [ -z "$1" ]; then
    REDIS_CONF=/redis/etc/redis.conf
    if [ ! -f "${REDIS_CONF}" ]; then
      if [ -z "${REDIS_PASSWORD}" ]; then
        REDIS_PASSWORD=$(echo "${RANDOM}$(date)" | md5sum | cut -d' ' -f1);
        echo "redis password set to: ${REDIS_PASSWORD}, please set your own password via -e REDIS_PASSWORD or provide your own configuration!"
      fi
      cp /var/redis/default.conf ${REDIS_CONF}
      sed -i s/\$PASSWORD/${REDIS_PASSWORD}/ ${REDIS_CONF}
    fi
    set -- "redis-server" \
      ${REDIS_CONF}
  fi

  exec "$@"