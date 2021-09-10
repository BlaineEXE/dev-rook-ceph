#!/usr/bin/env bash

echo -n "Verifying basic Kubernetes cluster operations ... "

# assert that kubectl get nodes returns the expected number of masters+workers
node_count=$(kubectl get nodes --no-headers | wc -l)
node_count=${node_count%$'\r'} # node count comes back with \r on the end
if [[ $node_count -ne ${NODE_COUNT} ]]; then
  echo "  ERROR! Expected count (${NODE_COUNT}) does not match the actual node count (${node_count})!"
  exit 1
fi

echo "done."
