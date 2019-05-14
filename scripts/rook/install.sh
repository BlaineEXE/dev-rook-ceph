#!/usr/bin/env bash
set -euo pipefail

source scripts/shared.sh

INSTALL_TIMEOUT=${INSTALL_TIMEOUT:-300}

root_dir="${PWD}"

echo ''
echo 'INSTALLING CEPH'
( cd "${ROOK_CONFIG_DIR}"/ceph
  if [[ ! -s psp.yaml ]]; then
    default_psp="${root_dir}/scripts/rook/default-psp.yaml"
    echo "  WARNING! The current config branch lacks a 'psp.yaml' file."
    echo "           Using the dev-rook-ceph default '${default_psp}'."
    cp "${default_psp}" psp.yaml
  fi
  if [[ -s common.yaml ]]; then
    kubectl apply -f common.yaml -f psp.yaml -f operator.yaml
  else
    # this will be able to install Rook v0.9 manifests
    kubectl apply -f psp.yaml -f operator.yaml
  fi
  sleep 3 # I think it takes a while for the CRDs to create. Workaround by sleeping a few seconds.
  kubectl apply -f cluster.yaml -f toolbox.yaml
  sleep 3
  kubectl apply -f storageclass.yaml # allows block storage
)

# Wait for all osd prepare pods to be completed
num_osd_nodes=$((NUM_WORKERS + NUM_MASTERS))
wait_for "Ceph to be installed" ${INSTALL_TIMEOUT} \
  "[[ \$(kubectl get --namespace ${ROOK_NAMESPACE} pods 2>&1 | grep -c 'rook-ceph-osd-prepare.*Completed') -eq $num_osd_nodes ]]"

# osd_count="$(kubectl --namespace ${ROOK_NAMESPACE} get pod | grep -c osd-[[:digit:]] || true)"


cat <<EOF

CEPH STATUS:

EOF
exec_in_toolbox_pod ceph -s
