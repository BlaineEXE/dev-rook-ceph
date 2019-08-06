#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

# TODO: put in dev settings?
namespace="${KUBERNETES_DASHBOARD_NAMESPACE}"
service_account="${namespace}"
service_name="service/${namespace}"

secret_name="$( \
    kubectl -n ${namespace} get serviceaccounts -o json ${service_account} | \
        jq -r '.secrets[].name')"

token="$( \
    kubectl -n ${namespace} get -o json secret $secret_name | \
        jq -r '.data.token' | base64 -d -)"

local="${KUBERNETES_DASHBOARD_LOCAL_PORT}"

echo ""
echo "  Dashboard addr: https://127.0.0.1:${local}"
echo "  Dashboard user: admin"
echo "  Dashboard token: ${token}"
echo "  Use Ctrl-C to stop port forwarding when you are done."
echo ""

kubectl --namespace "${namespace}" port-forward "${service_name}" "${local}:443"
