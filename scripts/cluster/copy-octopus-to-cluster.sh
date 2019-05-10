#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

echo -n "Copying Octopus to the cluster nodes ... "

filename="$(basename ${OCTOPUS_TOOL})"

suppress_output_unless_error "${OCTOPUS} --host-groups all copy ${OCTOPUS_TOOL} /root/bin/"
suppress_output_unless_error "${OCTOPUS} --host-groups all run 'mv /root/bin/${filename} /root/bin/octopus'"
suppress_output_unless_error "${OCTOPUS} --host-groups all copy --recursive _node-list /root/"

echo "done."
