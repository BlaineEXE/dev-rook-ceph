
UPGRADE_FROM_CONFIG_DIR ?= $(PWD)/.upgrade-from-config
UPGRADE_TO_CONFIG_DIR ?= $(PWD)/.upgrade-to-config

UPGRADE_FROM_CONFIG_BRANCH_FILE := $(UPGRADE_FROM_CONFIG_DIR)/_current-config-branch
UPGRADE_TO_CONFIG_BRANCH_FILE := $(UPGRADE_TO_CONFIG_DIR)/_current-config-branch

## ABOUT
##  Test Rook upgrades. Upgrade tooling is currently very much a work-in-progress.
##  These will probably only work upgrading from Rook v0.9 to master.

# Upgrades might have slightly different configs from the master branch when features change
# Set overrides here for the upgrade environment
upgrade.environment.%:
	# e.g., $(eval VAR := newvalue)
# Delete the below once upgrades are from v1.0?
	$(eval MAKE := $(MAKE) ROOK_SYSTEM_NAMESPACE=rook-ceph-system)
	$(eval BASH := ROOK_SYSTEM_NAMESPACE=rook-ceph-system $(BASH))

##
## UPGRADE TARGETS
##   upgrade.from       Just as with ${TGT}rook.set-config${NON}, set a Rook config branch for configuring
##                          the before-upgrade cluster using the active Rook branch's configs.
$(UPGRADE_FROM_CONFIG_DIR): upgrade.environment.%
	@ echo "  ERROR! No branch has been set to upgrade from."
	@ exit 1
upgrade.from: upgrade.environment.%
	@ rm -rf $(UPGRADE_FROM_CONFIG_DIR)
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_FROM_CONFIG_DIR) rook.set-config.%
	@ $(MAKE) upgrade.showinfo

##   upgrade.to         Just as with ${TGT}rook.set-config${NON}, set a Rook config branch for configuring the
##                          post-upgrade cluster using the active Rook branch's configs.
$(UPGRADE_TO_CONFIG_DIR): upgrade.environment.%
	@ printf '  WARNING! No branch has been set to upgrade to\n'
	@ printf '  using configs from the current branch: %s\n' "$$(git -C rook/ rev-parse --abbrev-ref HEAD)"
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_TO_CONFIG_DIR) rook.copy-config.%
	@ $(MAKE) upgrade.showinfo
# ^ rook.copy-config.% doesn't store the cfg branch so upgrade 'to' continues to be the active branch
upgrade.to: upgrade.environment.%
	@ rm -rf $(UPGRADE_TO_CONFIG_DIR)
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_TO_CONFIG_DIR) rook.set-config.%
	@ $(MAKE) upgrade.showinfo

##   upgrade.unset-to   Just as with ${TGT}rook.unset-config${NON}, remove the stored configs for configuring
##                          the post-upgrade cluster. The post-upgrade cluster will always be
##                          configured from manifests in the active branch.
#  A 'from' branch is always required, so don't delete the from branch
upgrade.unset-to: upgrade.environment.%
	@ rm -rf $(UPGRADE_TO_CONFIG_DIR)
	@ $(MAKE) upgrade.showinfo

##   upgrade.install    Install the pre-upgrade cluster using configs set via ${TGT}upgrade.to${NON}.
upgrade.install:  upgrade.environment.% $(UPGRADE_FROM_CONFIG_DIR)
# increase install timeout to account for possible pulling of upstream images
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_FROM_CONFIG_DIR) INSTALL_TIMEOUT=450 rook.install
	@ $(BASH) scripts/upgrade/install-supplemental.sh

##   upgrade.uninstall  Uninstall the post- and pre-upgrade cluster resources.
upgrade.uninstall: $(UPGRADE_FROM_CONFIG_DIR)
	@ $(BASH) scripts/upgrade/uninstall-supplemental.sh
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_FROM_CONFIG_DIR) rook.uninstall

##   upgrade.rook       Upgrade Rook configs to those set via ${TGT}upgrade.set-to${NON} OR to the active
##                      branch's config if the 'to' config is not set.
upgrade.rook: $(UPGRADE_TO_CONFIG_DIR)
	@ $(BASH) scripts/upgrade/rook.sh
	@ bash scripts/resources/success-message.sh "UPGRADE IS COMMENCING. USER IS RESPONSIBLE FOR WATCHING UPGRADE."

NEW_CEPH_IMAGE ?= ceph/ceph:v14.2
##   upgrade.ceph       Upgrade the Ceph image to that defined by the env var ${ENV}NEW_CEPH_IMAGE${NON}.
##                          (default ${VAL}${NEW_CEPH_IMAGE}${NON})
upgrade.ceph:  upgrade.environment.%
	@ $(BASH) scripts/upgrade/ceph.sh
	@ bash scripts/resources/success-message.sh "UPGRADE IS COMMENCING. USER IS RESPONSIBLE FOR WATCHING UPGRADE."

##   upgrade.showinfo   Print ${TGT}rook.showinfo${NON} info supplemented with "from" and "to" config branches.
upgrade.showinfo: upgrade.environment.%
	@ $(MAKE) rook.showinfo
	@ echo "  UPGRADE FROM BRANCH: $$(cat $(UPGRADE_FROM_CONFIG_BRANCH_FILE) 2> /dev/null)"
	@ echo "  UPGRADE TO BRANCH: $$(cat $(UPGRADE_TO_CONFIG_BRANCH_FILE) 2> /dev/null)"
	@ echo ''

##
## DEV TARGETS
##  Because v1.0 changes the default Rook system namespace, these targets exist as a convenience for
##  using Rook dev targets in an upgrade context.
##
##   upgrade.operator-logs    Print and continue following the Rook operator log.
upgrade.operator-logs: upgrade.environment.%
	@ $(MAKE) rook.operator-logs

##   upgrade.restart-operator Restart the rook operator by deleting the pod.
upgrade.restart-operator: upgrade.environment.%
	@ $(MAKE) rook.restart-operator

#
# Help
#
.PHONY: upgrade.help
# Use sed on this makefile to render all lines beginning with '##'
upgrade.help: scripts/upgrade/Makefile.help
