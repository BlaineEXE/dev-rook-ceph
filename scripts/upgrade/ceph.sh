#!/usr/bin/env bash
set -Eeuo pipefail

kubectl --namespace "${ROOK_NAMESPACE}" patch CephCluster rook-ceph --type=merge \
    --patch "{\"spec\": {\"cephVersion\": {\"image\": \"${NEW_CEPH_IMAGE}\"}}}"
