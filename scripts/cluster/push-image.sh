#!/usr/bin/env bash
set -eEuo pipefail

# ARGS
local_image="$1"
remote_image="$2"

source scripts/shared.sh

# do this weird stuff but with podman
# https://hasura.io/blog/sharing-a-local-registry-for-minikube-37c7240d0615/

podman_port="$(podman machine inspect | jq -r '.[0].SSHConfig.Port')"

# -p : SSH port
# -i : identify file
# -TfN : disable TTY, go to background before command execution, do not execute command
# -R : remote port forward
PODMAN_PORT_FWD_CMD="ssh -p ${podman_port} -i ~/.ssh/podman-machine-default -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -TfN -R 5000:localhost:5000 core@localhost"
# PODMAN_PORT_FWD_CMD=(
#     ssh
#     -p 60449
#     -i ~/.ssh/podman-machine-default
#     -o "UserKnownHostsFile /dev/null"
#     -o "StrictHostKeyChecking no"
#     -TfN
#     -R 5000:localhost:5000
#     core@localhost
# )
KUBE_PORT_FWD_CMD="kubectl port-forward --namespace kube-system"

$PODMAN_PORT_FWD_CMD &

# Forward the registry port 5000 to the local host port 5000 in a background job
kube_registry_pod="$(kubectl -n kube-system get pod --selector k8s-app=kube-registry --output=name)"
$KUBE_PORT_FWD_CMD "${kube_registry_pod}" 5000:5000 >/dev/null &

function cleanup {
    pkill -f "$PODMAN_PORT_FWD_CMD" || true
    pkill -f "$KUBE_PORT_FWD_CMD" || true
}
trap cleanup EXIT

# Push image to registry
echo "    Pushing image to kube's registry"
$PODMAN tag "${local_image}" localhost:5000/"${remote_image}"
$PODMAN push --tls-verify=false "localhost:5000/${remote_image}"

# Pull the image on all nodes
echo "    Pulling image to all nodes"
suppress_output_unless_error "${MULTI_SSH} all 'crictl pull localhost:5000/${remote_image}'"

# Tag the image on all nodes as the desired remote image
# crictl can't tag images. 'minikube image tag' won't tag images without a library prefix
# suppress_output_unless_error "${MULTI_SSH} all 'crictl tag localhost:5000/${remote_image} ${remote_image}'"

cat /tmp/output
