#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

echo -n "Verifying basic cluster operations ... "

# Verify _node-list exists
if [ ! -f _node-list ]; then
  echo "  ERROR: _node-list file is not generated"
  exit 1
fi

# Verify octopus can reach all nodes
if ! ${OCTOPUS} -g all run 'hostname' 1>/dev/null; then
  echo "  ERROR: cannot run commands on cluster nodes"
  exit 1
fi

# Verify SSH connection to the cluster (via first master)
if ! ${BASH} ssh-to-cluster.sh hostname &>/dev/null ; then
  echo "  ERROR: cannot SSH to the cluster"
  exit 1
fi

echo "done."
