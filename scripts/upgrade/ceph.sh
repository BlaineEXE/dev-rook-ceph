#!/usr/bin/env bash
set -Eeuo pipefail

# outputs cephcluster.ceph.rook.io/<cluster-name>
cluster="$(kubectl --namespace "${ROOK_NAMESPACE}" get cephcluster --output name)"

kubectl --namespace "${ROOK_NAMESPACE}" patch "${cluster}" --type=merge \
    --patch "{\"spec\": {\"cephVersion\": {\"image\": \"${NEW_CEPH_IMAGE}\"}}}"
