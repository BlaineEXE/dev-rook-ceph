#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

DISPLAY_NAME="${KUBERNETES_DASHBOARD_NAMESPACE}"

# TODO: hack to grant perms to the dashboard
make_promiscuous()
{
    echo "  let ${DISPLAY_NAME} become promiscuous"

    local name="kubernetes-dashboard-cluster-admin"
    local cluster_role="cluster-admin"
    local service_account="kubernetes-dashboard:kubernetes-dashboard "

    suppress_output_unless_error " \
        kubectl get clusterrolebinding ${name} || \
        kubectl create clusterrolebinding ${name} \
            --clusterrole=${cluster_role} --serviceaccount=${service_account} \
    "

    echo "  forcfully restarting the ${DISPLAY_NAME} pod(s)"
    suppress_output_unless_error " \
        kubectl get pods -n ${KUBERNETES_DASHBOARD_NAMESPACE} -o yaml | \
        kubectl replace --force -f -
    "
}


echo "Installing ${DISPLAY_NAME} ..."

echo "  applying ${KUBERNETES_DASHBOARD_YAML}"
suppress_output_unless_error \
    "curl ${KUBERNETES_DASHBOARD_YAML} | kubectl apply -f -"

make_promiscuous

echo "... done."
