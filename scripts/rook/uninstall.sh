#!/usr/bin/env bash
# Do not die in the face of errors: set -Eeuo pipefail

source scripts/shared.sh

# BY DEFAULT, DO NOT FAIL ON BASH_CMD ERRORS
trap '' ERR

echo ''
echo 'DELETING ROOK RESOURCES'

# FIRST delete the Ceph cluster; if we don't do this and just try to delte all the resources, the
# next install may then detect a delete event at the end and then remove the cluster we want to test
cluster="$(kubectl --namespace ${ROOK_NAMESPACE} get CephCluster --output name)"
kubectl --namespace ${ROOK_NAMESPACE} delete "${cluster}" --wait=false

wait_for "CephCluster to start Terminating pods" 25 \
  "kubectl --namespace ${ROOK_NAMESPACE} get pod --no-headers | grep -q rook-ceph-mgr | grep Terminating"

# Wait for cluster pods to be done running; mgr is one of last to be deleted usually
wait_for "Rook resources to be deleted" 200 \
  "! kubectl --namespace ${ROOK_NAMESPACE} get pod --no-headers | grep -q rook-ceph-mgr"

# NEXT go through all the yaml files and do deletes on them to catch any other stuff
( cd "${ROOK_CONFIG_DIR}"/ceph
  del_args=""
  for f in $(find . -name '*.yaml'); do
    # kubectl delete -f "${f}" --wait=false
    del_args="${del_args} -f ${f}"
  done
  kubectl delete ${del_args} --wait=false
)

# Delete the test pod if it exists
delete_test_pod

# Rook won't overwrite existing data, so delete the data on rook destroy
echo ''
echo 'DELETING ROOK DATA FROM NODES'
${MULTI_SSH} all 'rm -rf /var/lib/rook'

set -Ee
${MULTI_SSH} all scripts/rook/disk-wipe-runner.sh
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
# if [[ $? -eq 0 ]]; then exit 0; fi

# If removing resources by files, sometimes resources get left in ETCD database, and usually it is a
# Rook-Ceph cluster that keeps its 'deleting' status and is deleted by k8s immediately after a new
# dev Rook-Ceph cluster is created. So find the Rook-/Ceph-related ETCD resources, and remove them.
# get the ETCD container on the master node (cannot be a pause container)
echo 'WIPE ETCD'
${MULTI_SSH} master scripts/rook/etcd-wipe-runner.sh
