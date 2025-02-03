#!/bin/ash
  redisconfig(){
    if [ ! -f "${REDIS_CONFIG}" ]; then
      eleven log warning "${REDIS_CONFIG} does not exist! Creating ..."
      cp ${APP_ROOT}/.default/default.conf ${REDIS_CONFIG}

      # check if redis password is set, if not create one
      if [ -z "${REDIS_PASSWORD}" ]; then
        DELIMITER=""
        for i in 1 2 3 4; do
          REDIS_PASSWORD="${REDIS_PASSWORD}${DELIMITER}$(echo "${RANDOM}$(date)" | md5sum | cut -d' ' -f1 | awk '{print substr($0, 0, 5)}')"
          DELIMITER="."
        done
        eleven log info "redis password not set, creating default password: ${REDIS_PASSWORD}"
        eleven log info "set your own password via -e REDIS_PASSWORD or use your own ${REDIS_CONFIG}"
      fi

      # enable authentication
      if cat "${REDIS_CONFIG}" | grep -qE '^masterauth'; then
        sed -i 's/^masterauth.*/masterauth '${REDIS_PASSWORD}'/' ${REDIS_CONFIG}
      else
        sed -i 's/# masterauth.*/masterauth '${REDIS_PASSWORD}'/' ${REDIS_CONFIG}
      fi

      if cat "${REDIS_CONFIG}" | grep -qE '^requirepass'; then
        sed -i 's/^requirepass.*/requirepass '${REDIS_PASSWORD}'/' ${REDIS_CONFIG}
      else
        sed -i 's/# requirepass.*/requirepass '${REDIS_PASSWORD}'/' ${REDIS_CONFIG}
      fi

      # enable TLS
      if [ ! -z ${REDIS_ENABLE_TLS} ]; then
        eleven log info "enable TLS"
        if [ ! -f "${APP_ROOT}/ssl/ca.crt" ]; then
            eleven log info "certificate ${APP_ROOT}/ssl/ca.crt is missing, creating ..."
            openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=REDIS/CN=CA" \
              -keyout ${APP_ROOT}/ssl/ca.key \
              -out ${APP_ROOT}/ssl/ca.crt \
              -days 3650 -nodes -sha256 &> /dev/null
          fi
          
          if [ ! -f "${APP_ROOT}/ssl/default.crt" ]; then
            eleven log info "certificate ${APP_ROOT}/ssl/default.crt is missing, creating and signing by CA ..."
            openssl req -x509 -newkey rsa:4096 -subj "/C=XX/ST=XX/L=XX/O=XX/OU=REDIS/CN=NODE" \
              -CA "${APP_ROOT}/ssl/ca.crt" \
              -CAkey "${APP_ROOT}/ssl/ca.key" \
              -keyout ${APP_ROOT}/ssl/default.key \
              -out ${APP_ROOT}/ssl/default.crt \
              -days 3650 -nodes -sha256 &> /dev/null
          fi

          sed -i 's/^# tls-port.*/tls-port 6379/' ${REDIS_CONFIG}
          sed -i 's/^port.*/port 0/' ${REDIS_CONFIG}
          sed -i 's/^tls-replication.*/tls-replication yes/' ${REDIS_CONFIG}
      fi

      # disable persistance
      if [ -n "${REDIS_DISABLE_PERSISTANCE}" ]; then
        eleven log warning "redis persistance is disabled, all data will be lost if redis is stopped!"
        sed -i 's/^save.*/save ""/' ${REDIS_CONFIG}
        sed -i 's/^appendonly.*/appendonly no/' ${REDIS_CONFIG}
        sed -i 's/^shutdown-on-sigint.*/shutdown-on-sigint nosave/' ${REDIS_CONFIG}
        sed -i 's/^shutdown-on-sigterm.*/shutdown-on-sigterm nosave/' ${REDIS_CONFIG}
      else
        sed -i 's/^save.*/save 3600 1 300 100 60 10000/' ${REDIS_CONFIG}
        sed -i 's/^appendonly.*/appendonly yes/' ${REDIS_CONFIG}
        sed -i 's/^shutdown-on-sigint.*/shutdown-on-sigint save/' ${REDIS_CONFIG}
        sed -i 's/^shutdown-on-sigterm.*/shutdown-on-sigterm save/' ${REDIS_CONFIG}
      fi

      # set as replication of a master node
      if [ -n "${REDIS_MASTER}" ]; then
        eleven log info "redis starting as replica from master ${REDIS_MASTER}"
        sed -i 's/^# replicaof.*/replicaof '${REDIS_MASTER}' 6379/' ${REDIS_CONFIG}
      else
        sed -i 's/^replicaof.*/# replicaof <masterip> <masterport>/' ${REDIS_CONFIG}
      fi

      # default
      sed -i 's@^pidfile.*@pidfile '${APP_ROOT}'/run/redis.pid@' ${REDIS_CONFIG}
      sed -i 's@^dir.*@dir '${APP_ROOT}'/var@' ${REDIS_CONFIG}
      sed -i 's/^protected-mode.*/protected-mode no/' ${REDIS_CONFIG}
      sed -i 's/^bind.*/bind 0.0.0.0/' ${REDIS_CONFIG}
    fi
  }

  sentinelconfig(){
    if [ ! -f "${REDIS_CONFIG}" ]; then
      # create default config for a three node cluster on default ports
      eleven log warning "${REDIS_CONFIG} does not exist! Creating ..."
      echo "port 26379" > ${REDIS_CONFIG}
      echo "sentinel monitor master-node ${REDIS_MASTER} 6379 2" >> ${REDIS_CONFIG}
      echo "sentinel down-after-milliseconds master-node 2000" >> ${REDIS_CONFIG}
      echo "sentinel failover-timeout master-node 3000" >> ${REDIS_CONFIG}
      echo "sentinel auth-pass master-node ${REDIS_PASSWORD}" >> ${REDIS_CONFIG}
      echo "sentinel announce-ip ${REDIS_IP}" >> ${REDIS_CONFIG}
    fi
  }

  if [ -z "${1}" ]; then
    redisconfig
    eleven log info "starting redis"
    set -- "redis-server" ${REDIS_CONFIG}
  else
    # check if redis-cli commands should be run
    if echo "$@" | grep -q "SET"; then
      redisconfig
      eleven log info "setting redis commands ..."
      redis-server ${REDIS_CONFIG} &> /dev/null &
      sleep 5
      for CMD in "$@"; do
        eleven log debug "${CMD}"
        if [ ! -z ${REDIS_ENABLE_TLS} ]; then
          REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli --tls --cacert ${APP_ROOT}/ssl/ca.crt ${CMD}
        else
          REDISCLI_AUTH=${REDIS_PASSWORD} redis-cli ${CMD}
        fi
      done
      kill -9 $(pgrep -f 'redis-server')
      eleven log info "starting redis"
      set -- "redis-server" ${REDIS_CONFIG}
    fi

    # check if sentinel should be run
    if echo "$@" | grep -q "sentinel"; then
      sentinelconfig
      eleven log info "starting sentinel"
      set -- "redis-server" ${REDIS_CONFIG} --sentinel
    fi
  fi

  exec "$@"