#!/usr/bin/env bash

source scripts/shared.sh
source _node-list

echo -n "Exercising SSH connections ... "
# prime the pump so to speak so that the nodes have tab complete ready for ssh-ing from the first
# master node to other nodes in the cluster
for node in ${all}; do
  suppress_output_unless_error "${OCTOPUS} --host-groups all run \
    'hn=\$(ssh -o StrictHostKeyChecking=no ${node} hostname) ; ssh -o StrictHostKeyChecking=no \$hn'"
done

echo "done."
