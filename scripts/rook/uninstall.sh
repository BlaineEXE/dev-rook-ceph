#!/usr/bin/env bash
# Do not die in the face of errors: set -Eeuo pipefail

source scripts/shared.sh

# BY DEFAULT, DO NOT FAIL ON BASH_CMD ERRORS
trap '' ERR

echo ''
echo 'DELETING ROOK RESOURCES'

# FIRST delete the Ceph cluster; if we don't do this and just try to delte all the resources, the
# next install may then detect a delete event at the end and then remove the cluster we want to test
kubectl --namespace ${ROOK_NAMESPACE} delete CephCluster ${ROOK_NAMESPACE} --wait=false
# Wait for cluster pods to be done running; mgr is one of last to be deleted usually
wait_for "Rook resources to be deleted" 210 \
  "! kubectl --namespace ${ROOK_NAMESPACE} get pod --no-headers | grep -q rook-ceph-mgr"

# NEXT go through all the yaml files and do deletes on them to catch any other stuff
( cd "${ROOK_CONFIG_DIR}"/ceph
  for f in $(find . -name '*.yaml'); do
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

set -Ee
${BASH_CMD} scripts/rook/wipe-disks.sh
set +Ee

# Wait for rook pods to be done running
# rook-ceph can take a long time to terminate
wait_for "Rook resources to be deleted" 210 \
  "! kubectl --namespace ${ROOK_NAMESPACE} get pod --no-headers | grep -q rook"

# Sometimes the ceph cluster CRD gets stuck in a state where it can't be deleted
kubectl patch crd/cephclusters.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge
sleep 3
kubectl delete crd/cephclusters.ceph.rook.io --wait=false

wait_for "Rook namespaces to be deleted" 210 \
  "! kubectl get namespaces | grep -q -e '${ROOK_SYSTEM_NAMESPACE}' -e '${ROOK_NAMESPACE}'"
if [[ $? -eq 0 ]]; then exit 0; fi

# # Sometimes we need to do this twice even :(
# kubectl patch crd/cephclusters.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge
# sleep 3
# kubectl delete crd/cephcluster.ceph.rook.io --wait=false

# wait_for "Rook namespaces to be deleted" 90 \
#   "! kubectl get namespaces | grep -q -e '${ROOK_SYSTEM_NAMESPACE}' -e '${ROOK_NAMESPACE}'"
