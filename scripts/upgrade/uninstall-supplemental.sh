#!/usr/bin/env bash

echo "Uninstalling additional upgrade resources that may apply..."

find ${UPGRADE_TO_CONFIG_DIR}/ceph/ -name 'crds.yaml' -exec kubectl delete -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ceph/ -name 'upgrade-*-crd*.yaml' -exec kubectl delete -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ceph/ -name 'upgrade-*-create.yaml' -exec kubectl delete -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ceph/ -name 'upgrade-*-apply.yaml' -exec kubectl delete -f {} \;

exit 0  # uninstallation is on a best-effort basis
