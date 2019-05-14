#!/usr/bin/env bash

# delete what may have been created
for delete_me in ${UPGRADE_TO_CONFIG_DIR}/ceph/upgrade-*-create.yaml; do
  kubectl delete -f "${delete_me}" --wait=false
done
