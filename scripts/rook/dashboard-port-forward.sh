#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

pass="$(kubectl --namespace "${ROOK_NAMESPACE}" get -o json secret rook-ceph-dashboard-password | \
            jq -r '.data.password' | base64 -d -)"
echo ""
echo "  Dashboard addr: https://127.0.0.1:8443"
echo "  Dashboard user: admin"
echo "  Dashboard pass: ${pass}"
echo "  Use Ctrl-C to stop port forwarding when you are done."
echo ""

kubectl --namespace "${ROOK_NAMESPACE}" port-forward service/rook-ceph-mgr-dashboard 8443
