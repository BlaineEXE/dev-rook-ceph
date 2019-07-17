#!/usr/bin/env bash
# Do not die in the face of errors: set -Eeuo pipefail

source scripts/shared.sh

# BY DEFAULT, DO NOT FAIL ON BASH ERRORS
trap '' ERR

echo ''
echo 'DELETING ROOK RESOURCES'
( cd "${ROOK_CONFIG_DIR}"/ceph
  for f in *.yaml; do
    kubectl delete -f "${f}" --wait=false
  done
)

# Rook won't overwrite existing data, so delete the data on rook destroy
echo ''
echo 'DELETING ROOK DATA FROM NODES'
${OCTOPUS} --host-groups all run \
  'dir=/home/ses     ; rm -rf "$dir"/* ; echo "$dir contents:" ; cd "$dir" 2>/dev/null && ls
   dir=/var/lib/rook ; rm -rf "$dir"/* ; echo "$dir contents:" ; cd "$dir" 2>/dev/null && ls
   exit 0'

${BASH} scripts/rook/wipe-disks.sh

# Wait for rook pods to be done running
# rook-ceph can take a long time to terminate
wait_for "Rook resources to be deleted" 210 \
  "! kubectl --namespace "${ROOK_NAMESPACE}" get pod --no-headers | grep -q rook"

# Sometimes the ceph cluster CRD gets stuck in a state where it can't be deleted
kubectl patch crd/cephclusters.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge
sleep 3
kubectl delete crd/cephcluster.ceph.rook.io --wait=false

# Wait for Rook's namespaces to be deleted before returning success

wait_for "Rook namespaces to be deleted" 90 \
  "! kubectl get namespaces | grep -q -e '${ROOK_SYSTEM_NAMESPACE}' -e '${ROOK_NAMESPACE}'"
