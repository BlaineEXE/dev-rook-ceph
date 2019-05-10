#!/usr/bin/env bash

source scripts/shared.sh

echo -n "Setting up .bashrc and environment ... "

suppress_output_unless_error "${OCTOPUS} --host-groups all copy scripts/cluster/{.alias,.bashrc} /root"

echo "done."
