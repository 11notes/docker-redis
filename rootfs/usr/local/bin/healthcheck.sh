#!/bin/ash
  if [ ! -z ${REDIS_ENABLE_TLS} ]; then
    REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli --tls --cacert ${REDIS_SSL}/ca.crt ping | grep -q 'PONG'
  else
    REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli ping | grep -q 'PONG'
  fi