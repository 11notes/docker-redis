#!/bin/ash
  if [ ! -f "${APP_ROOT}/ssl/ca.crt" ]; then
    echo "CA certificate missing, creating new CA"
    openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=CA" \
      -keyout "${APP_ROOT}/ssl/ca.key" \
      -out "${APP_ROOT}/ssl/ca.crt" \
      -days 3650 -nodes -sha256  &> /dev/null
  fi

  if [ ! -f "${APP_ROOT}/ssl/server.crt" ]; then    
    echo "Server certificate missing, creating new certificate signed by CA"
    openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=SERVER" \
      -CA "${APP_ROOT}/ssl/ca.crt" \
      -CAkey "${APP_ROOT}/ssl/ca.key" \
      -keyout "${APP_ROOT}/ssl/server.key" \
      -out "${APP_ROOT}/ssl/server.crt" \
      -days 3650 -nodes -sha256  &> /dev/null
  fi

  if [ -z "${1}" ]; then
    REDIS_CONF=/redis/etc/redis.conf
    if [ ! -f "${REDIS_CONF}" ]; then
      if [ -z "${REDIS_PASSWORD}" ]; then
        REDIS_PASSWORD=$(echo "${RANDOM}$(date)" | md5sum | cut -d' ' -f1);
        echo "redis password set to: ${REDIS_PASSWORD}, please set your own password via -e REDIS_PASSWORD or provide your own configuration!"
      fi
      cp /var/redis/default.conf ${REDIS_CONF}
      sed -i s/\$PASSWORD/${REDIS_PASSWORD}/ ${REDIS_CONF}
      sed -i s#\$SSL_ROOT#${APP_ROOT}/ssl# ${REDIS_CONF}
    fi
    set -- "redis-server" \
      ${REDIS_CONF}
  fi

  exec "$@"