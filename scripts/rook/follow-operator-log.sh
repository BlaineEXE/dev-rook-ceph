#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" logs --follow "$(get_operator_pod)"
