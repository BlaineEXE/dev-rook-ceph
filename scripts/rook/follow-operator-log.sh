#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

ROOK_SYSTEM_NAMESPACE='rook-ceph-system'

kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" logs --follow "$(get_operator_pod)"
