#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

echo -n "Restarting Rook operator ... "
kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" delete pod "$(get_operator_pod)"
echo "done."
