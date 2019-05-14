#!/usr/bin/env bash

# Print all the args to this script in a FAILURE! block and play a sad sound.
# This is good to use after long-running tasks

source scripts/shared.sh

cat <<EOF

FAILURE!
  $@

EOF

# tput bel
# sleep 0.1
# tput bel
# sleep 0.1
# tput bel
