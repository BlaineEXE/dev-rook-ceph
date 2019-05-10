#!/usr/bin/env bash

source scripts/shared.sh

echo -n "Setting iptables on nodes to be permissive ... "

suppress_output_unless_error "${OCTOPUS} --host-groups all run \
  'iptables -I INPUT -j ACCEPT && iptables -P INPUT ACCEPT'"

echo "done."
