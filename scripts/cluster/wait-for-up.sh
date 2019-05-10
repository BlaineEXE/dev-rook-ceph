#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

# sometimes the nodes fail very soon after a single hostname check returns true, so require that we
# have a successful result twice in a row 10 seconds apart
wait_for "all nodes to be up and ready" 90 \
  "${OCTOPUS} --host-groups all run 'hostname' 2>&1 && \
   sleep 10 && \
   ${OCTOPUS} --host-groups all run 'hostname' 2>&1"
