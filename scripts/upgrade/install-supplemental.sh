#!/usr/bin/env bash

source scripts/shared.sh

# install other daemons that normal install might not
( cd "${ROOK_CONFIG_DIR}"/ceph
  kubectl apply -f filesystem.yaml -f object.yaml -f nfs.yaml
)
