#!/usr/bin/env bash
set -eEuo pipefail

# delete existing PVs that might not be in ready state
pvs="$(kubectl get persistentvolumes --output=name)"
for pv in ${pvs}; do
  if [[ "${pv}" =~ "persistentvolume/local-" ]]; then
    kubectl delete "${pv}"
  fi
done

# MULTI_SSH stdout from all nodes is stored in /tmp/output
${MULTI_SSH} all scripts/kubernetes/local-pv-create-runner.sh

kubectl apply -f /tmp/output

cat <<EOF | kubectl apply -f -
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
