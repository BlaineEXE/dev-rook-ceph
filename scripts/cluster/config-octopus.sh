#!/usr/bin/env bash
set -Eeuo pipefail

echo -n "Generating Octopus config ... "

mkdir -p .octopus/
cat > .octopus/config.yaml << EOF
# As long as octopus is run from the root dir,
# it will reference the root nodes.

# Set our default keyfile
identity-file: "${PWD}/scripts/resources/.ssh/id_rsa"

# _node-list defines our groups
groups-file: "${PWD}/_node-list"

# default to connect to all nodes
host-groups: all
EOF

echo "done."
