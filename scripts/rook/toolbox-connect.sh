#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

kubectl --namespace "${ROOK_NAMESPACE}" exec -it "$(get_toolbox_pod)" -- bash
