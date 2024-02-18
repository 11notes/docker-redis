#!/bin/ash
  REDIS_CA_CERTIFICATE=${REDIS_CA_CERTIFICATE:-/redis/ssl/ca.crt}
  redis-cli --tls --raw --cacert ${REDIS_CA_CERTIFICATE} ping | grep -q 'PONG'