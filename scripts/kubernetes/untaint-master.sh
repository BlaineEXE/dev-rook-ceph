#!/usr/bin/env bash

noschedule_nodes="$(kubectl get nodes -o json | \
  jq -r '.items[] | select(.spec.taints[]?.key=="node-role.kubernetes.io/master" and .spec.taints[]?.effect=="NoSchedule") | .metadata.labels."kubernetes.io/hostname"' )"

for node in $noschedule_nodes; do
  kubectl taint node "${node}" node-role.kubernetes.io/master-
done
