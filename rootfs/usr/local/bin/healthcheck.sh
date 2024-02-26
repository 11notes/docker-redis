#!/bin/ash
  REDISCLI_AUTH=$(cat ${APP_ROOT}/etc/redis.conf | grep '^requirepass' | sed -E 's/^requirepass (\w+)/\1/')
  REDIS_CA_CERTIFICATE=${REDIS_CA_CERTIFICATE:-/redis/ssl/ca.crt}
  redis-cli --tls --raw --cacert ${REDIS_CA_CERTIFICATE} ping | grep -q 'PONG'