#!/usr/bin/env bash
set -eEuo pipefail

minikube_args=(
  --nodes="${NODE_COUNT}"
  --cpus="${NODE_CPUS}"
  --memory="${NODE_MEMORY_GB}gb"
  --extra-disks="${NODE_DISK_COUNT}"
)

if [[ -n "${NODE_DISK_SIZE_GB:-}" ]]; then
  minikube_args+=(--disk-size="${NODE_DISK_SIZE_GB}gb")
fi

minikube start --driver=hyperkit "${minikube_args[@]}"

# minikube addons enable registry

# This is a bit of a funny jq. minikube outputs an array if there are multiple nodes, but only an
# object if there is a single node. The 'arrays[], object' portion effectively outputs a bunch of
# objects if they are in an array or the object if it's just an object. See jq docs on the ','
# operator.
nodes="$(minikube status --output=json | jq -r '. | arrays[], objects | .Name')"

function render_node_ssh_config() {
  local name="$1"
  local ip="$2"
  local keyfile="$3"
  cat <<EOF
Host ${name}
  HostName ${ip}
  User docker
  Port 22
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile "${keyfile}"
  IdentitiesOnly yes
  LogLevel FATAL

EOF
}

# Generate ssh config
rm -f .cluster/node-list
rm -f .cluster/ssh_config
mkdir -p .cluster
for node in ${nodes}; do
  echo "${node}" >> .cluster/node-list
  ip="$(minikube ip --node="${node}")"
  keyfile="$(minikube ssh-key --node="${node}")"
  render_node_ssh_config "${node}" "${ip}" "${keyfile}" >> .cluster/ssh_config
done

# the 'minikube' node is the master node
echo '' >> .cluster/node-list # newline
cat <<EOF >> .cluster/node-list
[master]
minikube
EOF
