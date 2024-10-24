#!/bin/ash
  redisconfig(){
    if [ ! -f "${REDIS_CONF}" ]; then
      elevenLogJSON warning "${REDIS_CONF} does not exist! Creating ..."
      cp ${APP_ROOT}/.default/default.conf ${REDIS_CONF}

      # check if redis password is set, if not create one
      if [ -z "${REDIS_PASSWORD}" ]; then
        DELIMITER=""
        for i in 1 2 3 4; do
          REDIS_PASSWORD="${REDIS_PASSWORD}${DELIMITER}$(echo "${RANDOM}$(date)" | md5sum | cut -d' ' -f1 | awk '{print substr($0, 0, 5)}')"
          DELIMITER="."
        done
        elevenLogJSON info "redis password not set, creating default password: ${REDIS_PASSWORD}"
        elevenLogJSON info "set your own password via -e REDIS_PASSWORD or use your own ${REDIS_CONF}"
      fi

      # enable authentication
      if cat "${REDIS_CONF}" | grep -qE '^masterauth'; then
        sed -i 's/^masterauth.*/masterauth '${REDIS_PASSWORD}'/' ${REDIS_CONF}
      else
        sed -i 's/# masterauth.*/masterauth '${REDIS_PASSWORD}'/' ${REDIS_CONF}
      fi

      if cat "${REDIS_CONF}" | grep -qE '^requirepass'; then
        sed -i 's/^requirepass.*/requirepass '${REDIS_PASSWORD}'/' ${REDIS_CONF}
      else
        sed -i 's/# requirepass.*/requirepass '${REDIS_PASSWORD}'/' ${REDIS_CONF}
      fi

      # enable TLS
      if [ ! -z ${REDIS_ENABLE_TLS} ]; then
        elevenLogJSON info "enable TLS"
        if [ ! -f "${REDIS_SSL}/ca.crt" ]; then
            elevenLogJSON info "certificate ${REDIS_SSL}/ca.crt is missing, creating ..."
            openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=REDIS/CN=CA" \
              -keyout ${REDIS_SSL}/ca.key \
              -out ${REDIS_SSL}/ca.crt \
              -days 3650 -nodes -sha256 &> /dev/null
          fi
          
          if [ ! -f "${REDIS_SSL}/default.crt" ]; then
            elevenLogJSON info "certificate ${REDIS_SSL}/default.crt is missing, creating and signing by CA ..."
            openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=REDIS/CN=NODE" \
              -CA "${REDIS_SSL}/ca.crt" \
              -CAkey "${REDIS_SSL}/ca.key" \
              -keyout ${REDIS_SSL}/default.key \
              -out ${REDIS_SSL}/default.crt \
              -days 3650 -nodes -sha256 &> /dev/null
          fi

          sed -i 's/^# tls-port.*/tls-port 6379/' ${REDIS_CONF}
          sed -i 's/^port.*/port 0/' ${REDIS_CONF}
          sed -i 's/^tls-replication.*/tls-replication yes/' ${REDIS_CONF}
      fi

      # disable persistance
      if [ -n "${REDIS_DISABLE_PERSISTANCE}" ]; then
        elevenLogJSON warning "redis persistance is disabled, all data will be lost if redis is stopped!"
        sed -i 's/^save.*/save ""/' ${REDIS_CONF}
        sed -i 's/^appendonly.*/appendonly no/' ${REDIS_CONF}
        sed -i 's/^shutdown-on-sigint.*/shutdown-on-sigint nosave/' ${REDIS_CONF}
        sed -i 's/^shutdown-on-sigterm.*/shutdown-on-sigterm nosave/' ${REDIS_CONF}
      else
        sed -i 's/^save.*/save 3600 1 300 100 60 10000/' ${REDIS_CONF}
        sed -i 's/^appendonly.*/appendonly yes/' ${REDIS_CONF}
        sed -i 's/^shutdown-on-sigint.*/shutdown-on-sigint save/' ${REDIS_CONF}
        sed -i 's/^shutdown-on-sigterm.*/shutdown-on-sigterm save/' ${REDIS_CONF}
      fi

      # set as replication of a master node
      if [ -n "${REDIS_MASTER}" ]; then
        elevenLogJSON info "redis starting as replica from master ${REDIS_MASTER}"
        sed -i 's/^# replicaof.*/replicaof '${REDIS_MASTER}' 6379/' ${REDIS_CONF}
      else
        sed -i 's/^replicaof.*/# replicaof <masterip> <masterport>/' ${REDIS_CONF}
      fi

      # default
      sed -i 's@^pidfile.*@pidfile '${APP_ROOT}'/run/redis.pid@' ${REDIS_CONF}
      sed -i 's@^dir.*@dir '${APP_ROOT}'/var@' ${REDIS_CONF}
      sed -i 's/^protected-mode.*/protected-mode no/' ${REDIS_CONF}
      sed -i 's/^bind.*/bind 0.0.0.0/' ${REDIS_CONF}
    fi
  }

  sentinelconfig(){
    if [ ! -f "${REDIS_CONF}" ]; then
      # create default config for a three node cluster on default ports
      elevenLogJSON warning "${REDIS_CONF} does not exist! Creating ..."
      echo "port 26379" > ${REDIS_CONF}
      echo "sentinel monitor master-node ${REDIS_MASTER} 6379 2" >> ${REDIS_CONF}
      echo "sentinel down-after-milliseconds master-node 2000" >> ${REDIS_CONF}
      echo "sentinel failover-timeout master-node 3000" >> ${REDIS_CONF}
      echo "sentinel auth-pass master-node ${REDIS_PASSWORD}" >> ${REDIS_CONF}
      echo "sentinel announce-ip ${REDIS_IP}" >> ${REDIS_CONF}
    fi
  }

  if [ -z "${1}" ]; then
    redisconfig
    elevenLogJSON info "starting redis"
    set -- "redis-server" ${REDIS_CONF}
  else
    # check if redis-cli commands should be run
    if echo "$@" | grep -q "SET"; then
      redisconfig
      elevenLogJSON info "setting redis commands ..."
      redis-server ${REDIS_CONF} &> /dev/null &
      sleep 5
      for CMD in "$@"; do
        elevenLogJSON debug "${CMD}"
        if [ ! -z ${REDIS_ENABLE_TLS} ]; then
          REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli --tls --cacert ${REDIS_SSL}/ca.crt ${CMD}
        else
          REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli ${CMD}
        fi
      done
      kill -9 $(pgrep -f 'redis-server')
      elevenLogJSON info "starting redis"
      set -- "redis-server" ${REDIS_CONF}
    fi

    # check if sentinel should be run
    if echo "$@" | grep -q "sentinel"; then
      sentinelconfig
      elevenLogJSON info "starting sentinel"
      set -- "redis-server" ${REDIS_CONF} --sentinel
    fi
  fi

  exec "$@"