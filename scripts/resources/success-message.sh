#!/usr/bin/env bash

# Print all the args to this script in a SUCCESS! block and play a happy sound.
# This is good to use after long-running tasks

source scripts/shared.sh

cat <<EOF

SUCCESS!
  $@

EOF

tput bel
