#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

INSTALL_TIMEOUT=${INSTALL_TIMEOUT:-900}

echo ''
echo 'INSTALLING ROOK-CEPH'

( cd "${ROOK_CONFIG_DIR}"/ceph
  if [[ -s crds.yaml ]]; then
    # crds.yaml was added for Rook v1.5
    kubectl apply -f crds.yaml
  fi
  kubectl apply -f common.yaml

  # apply a modified operator.yaml
  # set debug log level (in env var or configmap)
  # change rook/ceph:master image to use local registry's copy of image
  sed -e 's|value: "INFO"|value: "DEBUG"|' \
      -e 's|ROOK_LOG_LEVEL: "INFO"|ROOK_LOG_LEVEL: "DEBUG"|' \
      -e 's|rook/ceph:master|localhost:5000/rook/ceph:master|' operator.yaml | kubectl apply -f -
  # kubectl apply -f operator.yaml

  # Set the Rook log level to Debug after creating the operator deployment for our development
  # kubectl --namespace "${ROOK_NAMESPACE}" set env deployment/rook-ceph-operator ROOK_LOG_LEVEL=DEBUG

  sleep 10 # I think it takes a while for the CRDs to create. Workaround by sleeping a few seconds.
  kubectl apply -f "${ROOK_CLUSTER_FILE}" -f toolbox.yaml

  sleep 3
  kubectl apply -f "${ROOK_BLOCK_FILE}"
)

# Wait for all osd prepare pods to be completed
num_osd_nodes=$(( NODE_COUNT + 1 ))
wait_for "Ceph to be installed" "${INSTALL_TIMEOUT}" \
  "[[ \$(kubectl get --namespace '${ROOK_NAMESPACE}' pods 2>&1 | grep -c 'rook-ceph-osd-prepare.*Completed') -eq $num_osd_nodes ]]"


cat <<EOF

CEPH STATUS:

EOF
# try multiple times in case first time errors
time while ! exec_in_toolbox_pod ceph -s; do
  echo "Trying again... :|"
  sleep 5
done
