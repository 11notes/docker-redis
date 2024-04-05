#!/bin/ash
  for DEP in */; do
    DEP=$(echo ${DEP} | sed -E 's#\/##')
    if ! echo "${DEP}" | grep -q 'jemalloc'; then
      make ${DEP}
    fi
  done