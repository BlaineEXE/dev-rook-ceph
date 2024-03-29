#!/usr/bin/env bash

echo "Uninstalling additional upgrade resources that may apply..."

find ${UPGRADE_TO_CONFIG_DIR}/ -name 'crds.yaml' -exec kubectl delete --wait=false -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-crd*.yaml' -exec kubectl delete --wait=false -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-create.yaml' -exec kubectl delete --wait=false -f {} \;
find ${UPGRADE_TO_CONFIG_DIR}/ -name 'upgrade-*-apply.yaml' -exec kubectl delete --wait=false -f {} \;

exit 0  # uninstallation is on a best-effort basis
