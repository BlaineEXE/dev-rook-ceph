#!/usr/bin/env bash

source scripts/shared.sh

# Make sure we can use the kubeconfig file to interact with the cluster
# Depending on what happened before this, the docker/kubelet daemons might be in the process of
# restarting on the nodes, so give them some time to come back online before failing.
wait_for "Kubernetes nodes to be online" 60 "kubectl get nodes 2>&1"
