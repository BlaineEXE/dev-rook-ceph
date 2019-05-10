#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

echo ""
echo "REPLACING ROOK OPERATOR"
kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" delete pod "$(get_operator_pod)"
