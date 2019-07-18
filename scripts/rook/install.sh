#!/usr/bin/env bash
set -euo pipefail

source scripts/shared.sh

INSTALL_TIMEOUT=${INSTALL_TIMEOUT:-450}

root_dir="${PWD}"

echo ''
echo 'INSTALLING CEPH'

DEFAULT_PSP="${root_dir}/scripts/rook/default-psp.yaml"

( cd "${ROOK_CONFIG_DIR}"/ceph
  if [[ -s common.yaml ]]; then
    # common.yaml does not exist for v0.9
    kubectl apply -f common.yaml
  fi
  if ! grep -q 'kind: PodSecurityPolicy' common.yaml 2>/dev/null ; then
    # pod security policies were added into common.yaml for v1.1, so if common doesn't exist or
    # doesn't have psp info, we need to use a psp.yaml file
    if [ ! -f psp.yaml ]; then
      echo "  WARNING! The current config branch lacks a 'psp.yaml' file."
      echo "           Using the dev-rook-ceph default '${DEFAULT_PSP}'."
      cp "${DEFAULT_PSP}" psp.yaml
    fi
    kubectl apply -f psp.yaml
  fi
  kubectl apply -f operator.yaml

  sleep 10 # I think it takes a while for the CRDs to create. Workaround by sleeping a few seconds.
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
