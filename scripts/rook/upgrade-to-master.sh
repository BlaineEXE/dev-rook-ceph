#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" set image deploy/rook-ceph-operator \
  rook-ceph-operator=rook/ceph:master

# wait a few seconds for the new operator pod to start creating
sleep 10

# wait until there is only one operator pod (the new one)
wait_for "a single operator pod" 60 \
  "[[ $(get_operator_pod | grep -c operator) -eq 1 ]]"

bash ${BASHFLAGS:=} rook-follow-operator-log.sh
