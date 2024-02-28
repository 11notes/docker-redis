#!/bin/ash
  if [ -z "${1}" ]; then
    REDIS_CONF=${APP_ROOT}/etc/default.conf
    REDIS_SSL=${APP_ROOT}/ssl

    if [ ! -f "${REDIS_SSL}/ca.crt" ]; then
      elevenLogJSON info "certificate ${REDIS_SSL}/ca.crt is missing, creating ..."
      openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=CA" \
        -keyout ${REDIS_SSL}/ca.key \
        -out ${REDIS_SSL}/ca.crt \
        -days 3650 -nodes -sha256 &> /dev/null
    fi
    
    if [ ! -f "${REDIS_SSL}/default.crt" ]; then
      elevenLogJSON info "certificate ${REDIS_SSL}/default.crt is missing, creating and signing by CA ..."
      openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=XX/CN=REDIS" \
        -CA "${REDIS_SSL}/ca.crt" \
        -CAkey "${REDIS_SSL}/ca.key" \
        -keyout ${REDIS_SSL}/default.key \
        -out ${REDIS_SSL}/default.crt \
        -days 3650 -nodes -sha256 &> /dev/null
    fi

    if [ ! -f "${REDIS_CONF}" ]; then
      if [ -z "${REDIS_PASSWORD}" ]; then
        REDIS_PASSWORD=$(echo "${RANDOM}$(date)" | md5sum | cut -d' ' -f1);
        elevenLogJSON info "redis password not set, creating default password: ${REDIS_PASSWORD}"
        elevenLogJSON info "set your own password via -e REDIS_PASSWORD or use your own redis.conf"
      fi

      elevenLogJSON info "creating copy of default config from ${APP_ROOT}/.default/default.conf"

      cp ${APP_ROOT}/.default/default.conf ${REDIS_CONF}
      sed -i s/\$PASSWORD/${REDIS_PASSWORD}/ ${REDIS_CONF}
    fi

    if [ -n "${REDIS_DISABLE_PERSISTANCE}" ]; then
      elevenLogJSON warning "redis persistance is disabled, all data will be lost if redis is stopped!"
      sed -i 's/^save.*/save ""/' ${REDIS_CONF}
      sed -i 's/^appendonly yes/appendonly no/' ${REDIS_CONF}
      sed -i 's/^shutdown-on-sigint save/shutdown-on-sigint nosave/' ${REDIS_CONF}
      sed -i 's/^shutdown-on-sigterm save/shutdown-on-sigterm nosave/' ${REDIS_CONF}
    else
      sed -i 's/^save.*/save 3600 1 300 100 60 10000/' ${REDIS_CONF}
      sed -i 's/^appendonly no/appendonly yes/' ${REDIS_CONF}
      sed -i 's/^shutdown-on-sigint nosave/shutdown-on-sigint save/' ${REDIS_CONF}
      sed -i 's/^shutdown-on-sigterm nosave/shutdown-on-sigterm save/' ${REDIS_CONF}
    fi

    if [ -n "${REDIS_DISABLE_TLS}" ]; then
      elevenLogJSON info "disable TLS"
      sed -i 's/^tls-port 6379/# tls-port 6379/' ${REDIS_CONF}
      sed -i 's/^port .*/port 6379/' ${REDIS_CONF}
      sed -i 's/^tls-replication yes/tls-replication no/' ${REDIS_CONF}
    else
      sed -i 's/^# tls-port 6379/tls-port 6379/' ${REDIS_CONF}
      sed -i 's/^port .*/port 0/' ${REDIS_CONF}
      sed -i 's/^tls-replication no/tls-replication yes/' ${REDIS_CONF}
    fi

    if [ -n "${REDIS_MASTER}" ]; then
      elevenLogJSON info "redis starting as replica from master ${REDIS_MASTER}"
      sed -i 's/^# replicaof <masterip> <masterport>/replicaof '${REDIS_MASTER}' 6379/' ${REDIS_CONF}
      sed -i 's/^# masterauth <master-password>/masterauth '${REDIS_PASSWORD}'/' ${REDIS_CONF}
    else
      sed -i 's/^replicaof .*/# replicaof <masterip> <masterport>/' ${REDIS_CONF}
      sed -i 's/^masterauth .*/# masterauth <master-password>/' ${REDIS_CONF}
    fi

    set -- "redis-server" ${REDIS_CONF}

  fi

  exec "$@"