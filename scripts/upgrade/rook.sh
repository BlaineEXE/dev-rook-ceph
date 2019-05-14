#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

from_branch="$(cat "${UPGRADE_FROM_CONFIG_BRANCH_FILE}")"
to_branch="the current branch"
if [[ -s "${UPGRADE_TO_CONFIG_BRANCH_FILE}" ]]; then
  to_branch="branch '$(cat "${UPGRADE_TO_CONFIG_BRANCH_FILE}")'"
fi
echo "Upgrading Rook from config in branch '${from_branch}' to config in ${to_branch} ... "

for delete_me in ${UPGRADE_TO_CONFIG_DIR}/ceph/upgrade-*-delete.yaml; do
  kubectl delete -f "${delete_me}"
done

for create_me in ${UPGRADE_TO_CONFIG_DIR}/ceph/upgrade-*-create.yaml; do
  kubectl apply -f "${create_me}"
done

kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" set image deploy/rook-ceph-operator \
  rook-ceph-operator=rook/ceph:master

echo "  ... done. The upgrade is commencing."
