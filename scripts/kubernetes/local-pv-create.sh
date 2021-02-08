#!/usr/bin/env bash
set -eEuo pipefail

${MULTI_SSH} all scripts/kubernetes/local-pv-create-runner.sh

cat <<EOF | kubectl apply -f -
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
