#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh
source _node-list

echo -n "  downloading the admin kubeconfig file locally ..."

scp -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    -i "${PWD}"/scripts/resources/.ssh/id_rsa \
  root@"${first_master}":/root/.kube/config "${KUBECONFIG}"

echo "done."
