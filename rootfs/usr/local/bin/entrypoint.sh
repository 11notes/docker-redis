#!/bin/ash
  if [ -z "$1" ]; then
    set -- "redis-server" \
      /redis/etc/redis.conf
  fi

  exec "$@"