
UPGRADE_FROM_CONFIG_DIR ?= $(PWD)/.upgrade-from-config
UPGRADE_TO_CONFIG_DIR ?= $(PWD)/.upgrade-to-config

UPGRADE_FROM_CONFIG_BRANCH_FILE := $(UPGRADE_FROM_CONFIG_DIR)/_current-config-branch
UPGRADE_TO_CONFIG_BRANCH_FILE := $(UPGRADE_TO_CONFIG_DIR)/_current-config-branch

##
## ABOUT
##  Test Rook upgrades. Upgrade tooling is currently very much a work-in-progress.
##  These will probably only work upgrading from Rook v0.9 to master.
##
## BASIC WORKFLOW
##  Upgrades are done by first installing a before-upgrade Rook-Ceph using configs in a "from" branch.
##  Rook may then be upgraded to a new version using configs in a "to" branch. Ceph may also be
##  upgraded to a new version either before or after the Rook upgrade.
##    1.  Store the before-upgrade configs      ${CMD}make upgrade.from${NON}  (from before-upgrade config branch)
##    2.  Store the post-upgrade configs        ${CMD}make upgrade.to${NON}    (from post-upgrade config branch)
##    3.  Build and push Rook images to hosts   ${CMD}make rook.build${NON}    (from working branch)
##    4a. Kick off a Rook upgrade               ${CMD}make upgrade.rook${NON}                    (from any branch)
##    4b. Kick off a Ceph upgrade               ${CMD}make upgrade.ceph NEW_CEPH_IMAGE=<?>${NON} (from any branch)
##    5.  Manually verify the upgrade           See ${HDR}DEV${NON} targets from ${CMD}make rook.help${NON}  (from any branch)
##    6.  To iterate, repeat steps 3 onward
##    7.  Uninstall before starting a new flow  ${CMD}make upgrade.uninstall${NON}               (from any branch)

##
## UPGRADE TARGETS
##   upgrade.from       Just as with ${TGT}rook.set-config${NON}, set configs for the before-upgrade cluster by
##                          copying the current branch's configs to ${DIR}.upgrade-from-config/${NON}.
$(UPGRADE_FROM_CONFIG_DIR):
	@ echo "  ERROR! No branch has been set to upgrade from."
	@ exit 1
upgrade.from:
	@ rm -rf $(UPGRADE_FROM_CONFIG_DIR)
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_FROM_CONFIG_DIR) rook.set-config.%
	@ $(MAKE) upgrade.showinfo

##   upgrade.to         Just as with ${TGT}rook.set-config${NON}, set configs for the post-upgrade cluster by
##                          copying the current branch's configs to ${DIR}.upgrade-to-config/${NON}.
$(UPGRADE_TO_CONFIG_DIR):
	@ printf '  WARNING! No branch has been set to upgrade to\n'
	@ printf '  using configs from the current branch: %s\n' "$$(git -C rook/ rev-parse --abbrev-ref HEAD)"
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_TO_CONFIG_DIR) rook.copy-config.%
	@ $(MAKE) upgrade.showinfo
# ^ rook.copy-config.% doesn't store the cfg branch so upgrade 'to' continues to be the active branch
upgrade.to:
	@ rm -rf $(UPGRADE_TO_CONFIG_DIR)
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_TO_CONFIG_DIR) rook.set-config.%
	@ $(MAKE) upgrade.showinfo

##   upgrade.unset-to   Just as with ${TGT}rook.unset-config${NON}, remove the stored post-upgrade cluster
##                          configs, causing the post-upgrade cluster to always be configured from
##                          manifests in the active branch.
#  A 'from' branch is always required, so don't delete the from branch
upgrade.unset-to:
	@ rm -rf $(UPGRADE_TO_CONFIG_DIR)
	@ $(MAKE) upgrade.showinfo

##   upgrade.install    Install the pre-upgrade cluster using configs set via ${TGT}upgrade.to${NON}.
upgrade.install:  $(UPGRADE_FROM_CONFIG_DIR)
# increase install timeout to account for possible pulling of upstream images
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_FROM_CONFIG_DIR) INSTALL_TIMEOUT=450 rook.install
	@ $(BASH_CMD) scripts/upgrade/install-supplemental.sh

##   upgrade.uninstall  Uninstall the post- and pre-upgrade cluster resources.
upgrade.uninstall: $(UPGRADE_FROM_CONFIG_DIR)
	@ $(BASH_CMD) scripts/upgrade/uninstall-supplemental.sh
	@ $(MAKE) ROOK_CONFIG_DIR=$(UPGRADE_FROM_CONFIG_DIR) rook.uninstall

##   upgrade.rook       Upgrade Rook configs to those set via ${TGT}upgrade.set-to${NON} OR to the active
##                      branch's config if the 'to' config is not set.
upgrade.rook: $(UPGRADE_TO_CONFIG_DIR)
	@ $(BASH_CMD) scripts/upgrade/rook.sh
	@ bash scripts/resources/success-message.sh "UPGRADE IS COMMENCING. USER IS RESPONSIBLE FOR WATCHING UPGRADE."

NEW_CEPH_IMAGE ?= ceph/ceph:v14.2
##   upgrade.ceph       Upgrade the Ceph image to that defined by the env var ${ENV}NEW_CEPH_IMAGE${NON}.
##                          (default ${VAL}${NEW_CEPH_IMAGE}${NON})
upgrade.ceph:
	@ $(BASH_CMD) scripts/upgrade/ceph.sh
	@ bash scripts/resources/success-message.sh "UPGRADE IS COMMENCING. USER IS RESPONSIBLE FOR WATCHING UPGRADE."

##   upgrade.showinfo   Print ${TGT}rook.showinfo${NON} info supplemented with "from" and "to" config branches.
upgrade.showinfo:
	@ $(MAKE) rook.showinfo
	@ echo "  UPGRADE FROM BRANCH: $$(cat $(UPGRADE_FROM_CONFIG_BRANCH_FILE) 2> /dev/null)"
	@ echo "  UPGRADE TO BRANCH: $$(cat $(UPGRADE_TO_CONFIG_BRANCH_FILE) 2> /dev/null)"
	@ echo ''

#
# Help
#
.PHONY: upgrade.help
# Use sed on this makefile to render all lines beginning with '##'
upgrade.help: scripts/upgrade/Makefile.help
