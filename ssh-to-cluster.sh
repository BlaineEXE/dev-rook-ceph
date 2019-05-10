#!/usr/bin/env bash
set -Eeuo pipefail

source _node-list
arr=(${masters}) # 'masters' from node list
first_master=${arr[0]}

ssh -q -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no \
    -i "${PWD}"/scripts/resources/.ssh/id_rsa -t root@"${first_master}" ${@}
