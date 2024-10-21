#!/bin/ash
  REDIS_PORT=$(netstat -tulpn | grep redis-server | grep -Eo '[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}:([0-9]{1,5})' | awk '{split($0,a,":"); print a[2]}')
  if [ ! -z ${REDIS_ENABLE_TLS} ]; then
    REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli -p ${REDIS_PORT} --tls --cacert ${REDIS_SSL}/ca.crt ping | grep -q 'PONG'
  else
    REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli -p ${REDIS_PORT} ping | grep -q 'PONG'
  fi