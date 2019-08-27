#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

echo 'WIPE CEPH DISKS'

# disk wiping is complicated, so copy the script to the nodes, then execute that
${OCTOPUS} --host-groups all copy scripts/rook/rook-disk-wipe-runner.sh /root
${OCTOPUS} --host-groups all run "${BASH_CMD} /root/rook-disk-wipe-runner.sh"
