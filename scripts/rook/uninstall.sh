#!/usr/bin/env bash
# Do not die in the face of errors: set -Eeuo pipefail

source scripts/shared.sh

# BY DEFAULT, DO NOT FAIL ON BASH ERRORS
trap '' ERR

echo ''
echo 'DELETING ROOK RESOURCES'
( cd ${ROOK_CONFIG_DIR}/ceph
  for f in *.yaml; do
    kubectl delete -f "${f}"
  done
  # kubectl delete -f psp.yaml -f cluster.yaml -f operator.yaml -f storageclass.yaml \
  #   -f filesystem.yaml -f toolbox.yaml
  # kubectl patch crd/cephclusters.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge
)

# Rook won't overwrite existing data, so delete the data on rook destroy
echo ''
echo 'DELETING ROOK DATA FROM NODES'
${OCTOPUS} --host-groups all run \
  'dir=/home/ses     ; rm -rf "$dir"/* ; echo "$dir contents:" ; cd "$dir" 2>/dev/null && ls
   dir=/var/lib/rook ; rm -rf "$dir"/* ; echo "$dir contents:" ; cd "$dir" 2>/dev/null && ls
   exit 0'

# disk wiping is complicated, so copy the script to the nodes, then execute that
${OCTOPUS} --host-groups all copy scripts/rook/rook-disk-wipe-runner.sh /root
${OCTOPUS} --host-groups all run "${BASH} /root/rook-disk-wipe-runner.sh"

# Sometimes the ceph cluster CRD gets stuck in a state where it can't be deleted
kubectl patch crd/cephclusters.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge

# Wait for Rook's namespaces to be deleted before returning success
# rook-ceph can take a long time to terminate
wait_for "Rook resources to be deleted" 300 \
  "! kubectl get namespaces | grep -q -e 'rook-ceph-system' -e 'rook-ceph'"
