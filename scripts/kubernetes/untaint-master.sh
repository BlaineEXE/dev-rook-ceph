#!/usr/bin/env bash

source scripts/shared.sh

echo -n "Untainting master node(s) ... "

noschedule_nodes="$(kubectl get nodes -o json | \
  jq -r '.items[] | select(.spec.taints[]?.key=="node-role.kubernetes.io/master") | .metadata.labels."kubernetes.io/hostname"' )"

for node in $noschedule_nodes; do
  suppress_output_unless_error "kubectl taint node ${node} node-role.kubernetes.io/master-"
done

echo "done."
