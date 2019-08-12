#!/usr/bin/env bash
# Do not die in the face of errors: set -Eeuo pipefail

source scripts/shared.sh

echo 'WIPE CEPH DISKS'

# disk wiping is complicated, so copy the script to the nodes, then execute that
${OCTOPUS} --host-groups all copy scripts/rook/rook-disk-wipe-runner.sh /root
${OCTOPUS} --host-groups all run "/root/rook-disk-wipe-runner.sh"
