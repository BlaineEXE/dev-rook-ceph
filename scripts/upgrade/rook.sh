#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

from_branch="$(cat "${UPGRADE_FROM_CONFIG_BRANCH_FILE}")"
to_branch="the current branch"
if [[ -s "${UPGRADE_TO_CONFIG_BRANCH_FILE}" ]]; then
  to_branch="branch '$(cat "${UPGRADE_TO_CONFIG_BRANCH_FILE}")'"
fi
echo "Upgrading Rook from config in branch '${from_branch}' to config in ${to_branch} ... "

find ${UPGRADE_TO_CONFIG_DIR}/ -name 'crds.yaml' -exec kubectl apply -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-crd*.yaml' -exec kubectl apply -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-create.yaml' -exec kubectl create -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-apply.yaml' -exec kubectl apply -f {} \;

kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" set image deploy/rook-ceph-operator \
  rook-ceph-operator=rook/ceph:master

find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-delete.yaml' -exec kubectl delete -f {} \;

echo "  ... done. The upgrade is commencing."
