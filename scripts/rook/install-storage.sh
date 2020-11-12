#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

# install other daemons that normal install might not
( cd "${ROOK_CONFIG_DIR}"/ceph
  kubectl apply -f "${ROOK_FILESYSTEM_FILE}" -f "${ROOK_OBJECT_FILE}"
  if [[ -f "${ROOK_NFS_FILE}" ]]; then
    kubectl apply -f "${ROOK_NFS_FILE}" # nfs-test.yaml introduced in rook v1.5
  else
    kubectl apply -f nfs.yaml
  fi
)
