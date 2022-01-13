#!/usr/bin/env bash
# Do not die in the face of errors: set -Eeuo pipefail

set -eEuo pipefail

source scripts/shared.sh

# BY DEFAULT, DO NOT FAIL ON BASH_CMD ERRORS
trap '' ERR

echo ''
echo 'DELETING ROOK RESOURCES'

# delete these before the kinds in the namespace
kinds_outside_namespace=(
  "ObjectBucketClaim"
)

kinds_in_namespace=(
  "CephClient"
  "CephNFS"
  "CephObjectStoreUser"
  "CephObjectStore"
  "CephObjectZone"
  "CephObjectZoneGroup"
  "CephObjectRealm"
  "CephFilesystem"
  "CephFilesystemMirror"
  "CephBlockPool"
  "CephRBDMirror"
  # "CephCluster"
)

# Delete the test pod if it exists
delete_test_pod || true

for kind in "${kinds_outside_namespace[@]}"; do
  {
    resources="$(kubectl get --all-namespaces "${kind}" --no-headers \
      --output custom-columns=namespace:.metadata.namespace,name:.metadata.name)" || true
    while read -r ns_and_name; do
      if [[ -z $ns_and_name ]]; then continue; fi
      namespace="${ns_and_name%% *}"
      name="${ns_and_name##* }"
      kubectl --namespace "${namespace}" delete "${kind}" "${name}" # DO WAIT! --wait=false
    done <<< "${resources}"
  } & # in parallel so this doesn't take forever
done

# wait for child processes to be complete
wait

# delete ceph cluster
CLUSTER_NAME="$(kubectl --namespace "${ROOK_NAMESPACE}" get CephCluster --no-headers \
  --output custom-columns=name:.metadata.name)" || true
if [[ -n "${CLUSTER_NAME}" ]]; then
  # set the cleanup policy so Rook will clean disks automatically
  kubectl --namespace "${ROOK_NAMESPACE}" patch CephCluster "${CLUSTER_NAME}" \
    --type merge -p '{"spec":{"cleanupPolicy":{"confirmation":"yes-really-destroy-data"}}}'
  kubectl --namespace "${ROOK_NAMESPACE}" delete CephCluster "${CLUSTER_NAME}" --wait=false
fi

for kind in "${kinds_in_namespace[@]}"; do
  {
    # --output=name gives <kind>/<name> output, so use custom-columns to just get name
    resources="$(kubectl get --namespace "${ROOK_NAMESPACE}" "${kind}" --no-headers \
      --output custom-columns=name:.metadata.name)" || true
    while read -r name; do
      if [[ -z $name ]]; then continue; fi
      kubectl --namespace "${ROOK_NAMESPACE}" delete "${kind}" "${name}" --wait=false
    done <<< "${resources}"
  } & # in parallel so this doesn't take forever
done

# delete toolbox pod
kubectl --namespace "${ROOK_NAMESPACE}" delete deployment rook-ceph-tools --force --grace-period=0 --wait=false || true

# wait for child processes to be complete
wait

# wait for all resources except the operator, CSI pods, and toolbox to be done with deleting
wait_for "CephCluster to be deleted" 60 \
  "[[ \$(kubectl --namespace ${ROOK_NAMESPACE} get cephcluster 2>/dev/null) == '' ]]"

# no cluster, no cleanup job
if [[ -n "${CLUSTER_NAME}" ]]; then
  wait_for "cluster cleanup jobs to be complete" 210 \
    "[[ \$(kubectl --namespace ${ROOK_NAMESPACE} get pods | grep -c 'cluster-cleanup-job.*Completed') -eq ${NODE_COUNT} ]]"
fi

wait_for "rook-ceph-mon-endpoints configmap to be deleted" 45 \
  "! kubectl --namespace ${ROOK_NAMESPACE} get configmap rook-ceph-mon-endpoints"

# now go through all the yaml files and do deletes on them to delete the operator, rbac, and any
# other straggling things
( cd "${ROOK_CONFIG_DIR}"
  del_args=""
  for f in $(find . -name '*.yaml'); do
    # kubectl delete -f "${f}" --wait=false
    del_args="${del_args} -f ${f}"
  done
  kubectl delete ${del_args} --wait=false || true
)

# # Rook won't overwrite existing data, so delete the data on rook destroy
# echo ''
# echo 'DELETING ROOK DATA FROM NODES'
# ${MULTI_SSH} all 'rm -rf /var/lib/rook'

# set -Ee
# ${MULTI_SSH} all scripts/rook/disk-wipe-runner.sh
# set +Ee

# Wait for rook pods to be done running
# rook-ceph can take a long time to terminate
wait_for "remaining Rook resources to be deleted" 45 \
  "! kubectl --namespace ${ROOK_NAMESPACE} get pod --no-headers | grep -q rook"

# # Sometimes the ceph cluster CRD gets stuck in a state where it can't be deleted
# kubectl patch crd/cephclusters.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge
# kubectl patch crd/cephblockpools.ceph.rook.io -p '{"metadata":{"finalizers":[]}}' --type=merge
# sleep 3
# kubectl delete crd/cephclusters.ceph.rook.io --wait=false
# kubectl delete crd/cephblockpools.ceph.rook.io --wait=false

wait_for "Rook namespaces to be deleted" 45 \
  "! kubectl get namespaces | grep -q -e '${ROOK_SYSTEM_NAMESPACE}' -e '${ROOK_NAMESPACE}'"

# # show dangling resources
# kubectl api-resources --verbs=list --namespaced -o name \
#   | xargs -n 1 kubectl get --show-kind --ignore-not-found -n "${ROOK_NAMESPACE}"

# # If removing resources by files, sometimes resources get left in ETCD database, and usually it is a
# # Rook-Ceph cluster that keeps its 'deleting' status and is deleted by k8s immediately after a new
# # dev Rook-Ceph cluster is created. So find the Rook-/Ceph-related ETCD resources, and remove them.
# # get the ETCD container on the master node (cannot be a pause container)
# echo 'WIPE ETCD'
# ${MULTI_SSH} master scripts/rook/etcd-wipe-runner.sh
