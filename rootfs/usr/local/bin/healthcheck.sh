#!/bin/ash
  if [ -n "${REDIS_DISABLE_TLS}" ]; then
    REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli ping | grep -q 'PONG'
  else
    REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli --tls --cacert ${REDIS_CA_CERTIFICATE} ping | grep -q 'PONG'
  fi