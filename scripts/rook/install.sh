#!/usr/bin/env bash
set -euo pipefail

source scripts/shared.sh

echo ''
echo 'INSTALLING CEPH'
( cd ${ROOK_CONFIG_DIR}/ceph
  kubectl apply -f common.yaml -f psp.yaml -f operator.yaml
  sleep 3 # I think it takes a while for the CRDs to create. Workaround by sleeping a few seconds.
  kubectl apply -f cluster.yaml -f toolbox.yaml
  sleep 3
  kubectl apply -f storageclass.yaml # allows block storage
)

# Wait for all osd prepare pods to be completed
num_osd_nodes=$((NUM_WORKERS + NUM_MASTERS))
wait_for "Ceph to be installed" 300 \
  "[[ \$(kubectl get --namespace ${ROOK_NAMESPACE} pods 2>&1 | grep -c 'rook-ceph-osd-prepare.*Completed') -eq $num_osd_nodes ]]"

# osd_count="$(kubectl --namespace ${ROOK_NAMESPACE} get pod | grep -c osd-[[:digit:]] || true)"


cat <<EOF

CEPH STATUS:

EOF
exec_in_toolbox_pod ceph -s
