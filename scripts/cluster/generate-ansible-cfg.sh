#!/usr/bin/env bash

cat <<EOF
[defaults]
inventory = $PWD/.cluster/node-list
deprecation_warnings = False

[ssh_connection]
ssh_args = -F "$PWD/.cluster/ssh_config"
EOF
