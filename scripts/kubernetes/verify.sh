#!/usr/bin/env bash

echo -n "Verifying basic Kubernetes cluster operations ... "

# assert that kubectl get nodes returns the expected number of masters+workers
node_count=$(kubectl get nodes --no-headers | wc -l)
node_count=${node_count%$'\r'} # node count comes back with \r on the end
expected_count=$((NUM_MASTERS + NUM_WORKERS))
if [[ $node_count -ne $expected_count ]]; then
  echo "  ERROR! Expected count (${expected_count}) does not match the actual node count (${node_count})!"
  exit 1
fi

echo "done."
