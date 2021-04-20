#!/usr/bin/env bash
set -eEuo pipefail

# ARGS
local_image="$1"
remote_image="$2"

source scripts/shared.sh

PORT_FWD_CMD="kubectl port-forward --namespace kube-system"

# Forward the registry port 5000 to the local host port 5000 in a background job
kube_registry_pod="$(kubectl -n kube-system get pod --selector k8s-app=kube-registry --output=name)"
$PORT_FWD_CMD "${kube_registry_pod}" 5000:5000 >/dev/null &

function cleanup {
    pkill -f "$PORT_FWD_CMD"
}
trap cleanup EXIT

# Push image to registry
# push to the dev cluster's registry as 0.0.0.0:5000 to work with Docker Desktop on mac
$DOCKER tag "${local_image}" 0.0.0.0:5000/"${remote_image}"
$DOCKER push "0.0.0.0:5000/${remote_image}"
# must have 0.0.0.0:5000 set as an insecure registry in docker config

# Pull the image on all nodes
# images are read from the registry as localhost:5000 (not 0.0.0.0:5000)
suppress_output_unless_error "${MULTI_SSH} all 'docker pull localhost:5000/${remote_image}'"

# Tag the image on all nodes as the desired remote image
suppress_output_unless_error "${MULTI_SSH} all 'docker tag localhost:5000/${remote_image} ${remote_image}'"

cat /tmp/output
