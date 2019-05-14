# The theory behind makefile targets is that targets (or target groups) should not share the same
# 3 letters so tab complete is useful for the user. Ideally, the first 2 letters.

##
## BASIC WORKFLOW
##
##  This environment makes it possible to keep separate branches for config changes and code changes:
##    * 'config' branches with modified manifest files used for installing Rook with different
##      configurations. Rook manifests exist in ${DIR}rook/cluster/examples/kubernetes/ceph/${NON}.
##    * 'working' branches with code changes separate from any manifest file changes.
##
##  Using this pattern, a good dev workflow for Rook code is:
##    1. Copy Rook's install config                 ${CMD}make rook.set-config${NON}   (from config branch)
##    2. Build and push Rook images to hosts        ${CMD}make rook.build${NON}        (from working branch)
##    3. Install Rook                               ${CMD}make rook.install${NON}      (from any branch)
##    4. Uninstall Rook before using a new config   ${CMD}make rook.uninstall${NON}    (from any branch)

# Targets followed by '%' are hidden from make's tab complete. These targets can be called via
# `make target.%`; however, this is an advanced usage not documented in the help text.
# Run a Rook make target with only the Ceph backend

ROOK_REPO_DIR ?= $(GOPATH)/src/github.com/rook/rook
ROOK_CONFIG_DIR ?= $(PWD)/.rook-config
CURRENT_CONFIG_BRANCH_FILE := $(ROOK_CONFIG_DIR)/_current-config-branch
CURRENT_BUILT_BRANCH_FILE := scripts/rook/_current-built-branch


# make a symlink from the rook repo in the user's go path to here for easy access
rook.symlink.%:
	@ $(BASH) -c 'if [ ! -d $(ROOK_REPO_DIR) ]; then \
	    echo "  ERROR! Rook has not been cloned to the GOPATH; cannot continue!"; exit 1; fi'
	@ $(BASH) -c 'if [ ! -L rook ]; then ln -s $(ROOK_REPO_DIR) rook; fi'

rook.make.%: $(GO_TOOL) rook.symlink.%
	@ if [ ! -d rook/vendor/ ]; then $(BASH) scripts/rook/make-ceph.sh vendor; fi
	@ $(BASH) scripts/rook/make-ceph.sh $*

##
## ROOK BUILD/INSTALL TARGETS

##   rook.set-config    Set the config branch by copying the current Rook branch's manifest files to
##                          ${DIR}.rook-config/${NON}. This allows you to have a consistent Rook
##                          config regardless of branch changes.
rook.copy-config.%: rook.symlink.%
# only copy the configs, don't store the branch
	@ mkdir -p $(ROOK_CONFIG_DIR)
	@ cp -a rook/cluster/examples/kubernetes/* $(ROOK_CONFIG_DIR)/.
rook.set-config.%: rook.copy-config.%
# copy configs AND store the branch
# same as 'rook.set-config' but won't print 'rook.showinfo' afterwards; used by upgrade makefile
	@ git -C rook/ rev-parse --abbrev-ref HEAD > $(CURRENT_CONFIG_BRANCH_FILE)
$(CURRENT_CONFIG_BRANCH_FILE):
	@ printf '  WARNING! There is no record of a config branch set for use\n'
	@ printf '  using configs from the current branch: %s\n' "$$(git -C rook/ rev-parse --abbrev-ref HEAD)"
	@ $(MAKE) rook.copy-config.%
# ^ don't store the current branch in this case to keep using active branch by default
rook.config-branch-file.%: rook.symlink.% $(CURRENT_CONFIG_BRANCH_FILE) ;
# ^ use this to make a dependency on CURRENT_CONFIG_BRANCH_FILE so it gets symlink dependency too
rook.print-config-branch.%:
	@ echo "  CURRENT CONFIG BRANCH: $$(cat $(CURRENT_CONFIG_BRANCH_FILE) 2> /dev/null)"
rook.set-config: rook.set-config.%
	@ $(MAKE) rook.showinfo

##   rook.unset-config  Unset the config branch to always use manifests from the active branch.
rook.unset-config:
	@ rm -rf $(ROOK_CONFIG_DIR) # contains CURRENT_CONFIG_BRANCH_FILE

##   rook.build         Build Rook locally, and push the Rook image to nodes as 'rook/rook:master'
# Store branch name from most recent image built and pushed to nodes so we can print it for the user
# Makefile is more complicated, but gives the dev important reminder about what is being installed
$(CURRENT_BUILT_BRANCH_FILE):
	@ echo '  WARNING! There is no record of a built image pushed to nodes'
	@ echo '  This is not an error if the config file specifies an upstream image'
rook.print-built-branch.%:
	@ echo "  CURRENT BUILT BRANCH: $$(cat $(CURRENT_BUILT_BRANCH_FILE) 2> /dev/null)"
rook.build: rook.symlink.%
	@ printf "\n  BUILDING ROOK BRANCH %s\n" "$$(git -C rook/ rev-parse --abbrev-ref HEAD)"
	@ $(MAKE) rook.make.build
	@ $(BASH) scripts/rook/push.sh
	@ git -C rook/ rev-parse --abbrev-ref HEAD > $(CURRENT_BUILT_BRANCH_FILE) # store branch
	@ bash scripts/resources/success-message.sh "ROOK BUILT"
	@ $(MAKE) rook.showinfo

##   rook.install       Install Rook on the cluster with the config files set via ${TGT}rook.set-config${NON}
##                          OR uses the active branch's config if a config branch is unset or not set.
rook.install: rook.config-branch-file.%
	@ $(BASH) scripts/rook/install.sh
	@ $(BASH) scripts/rook/install-filesystem.sh
	@ $(BASH) scripts/resources/success-message.sh "ROOK INSTALLED"
	@ $(MAKE) rook.showinfo

##   rook.uninstall     Uninstall Rook from the cluster using the most recently set (or installed)
##                          config files. Run this target before copying new configs.
rook.uninstall: rook.config-branch-file.%
	@ $(BASH) scripts/rook/uninstall.sh
	@ $(MAKE) rook.showinfo
	@ sleep 10  # I think k8s needs time to flush the info from etcd
	@ $(BASH) scripts/resources/success-message.sh "ROOK UN-INSTALLED"

##   rook.reinstall     Uninstall and then re-install Rook with the same config and image.
rook.reinstall: rook.uninstall rook.install

##   rook.replace       Rebuild without reinstalling the cluster. When the image is built and
##                          pushed, the operator pod is restarted to run the new version. Useful for
##                          quickly iterating on Rook code changes.
rook.replace: rook.build
	@ $(BASH) scripts/rook/restart-operator.sh"
	@ $(MAKE) rook.showinfo
	@ bash scripts/resources/success-message.sh "ROOK IS REBUILT IN-PLACE"

##   rook.rebuild       Uninstall and build Rook, and then install Rook again with the same config.
##                          Useful in cases where rook.replace is insufficient.
rook.rebuild:
	@ # Uninstall and buildpush can be done in parallel; the rest must come after build
	@ $(MAKE) --jobs rook.uninstall rook.build
	@ $(MAKE) rook.install
	@ $(MAKE) rook.showinfo
	@ bash scripts/resources/success-message.sh "ROOK IS REBUILT AND REINSTALLED"

##   rook.reconfig      Uninstall Rook cluster, then install Rook again with the active branch's
##                          config. Useful for iterating on Rook config changes.
rook.reconfig: rook.uninstall rook.set-config rook.install rook.showinfo
	@ bash scripts/resources/success-message.sh "ROOK IS REINSTALLED WITH A NEW CONFIG"

##   rook.test          Run unit tests on Rook.
rook.test: rook.make.test
	@ bash scripts/resources/success-message.sh "ROOK UNIT TESTS PASSED"

##   rook.show-info     Print info about the current Rook install/config.
rook.showinfo:
	@ echo ''
	@ $(MAKE) rook.print-config-branch.%
	@ $(MAKE) rook.print-built-branch.%
	@ echo ''

##
## ROOK DEV/DEBUG TARGETS
##
##   rook.toolbox-connect  Connect to the Rook toolbox.
rook.toolbox-connect:
	@ $(BASH) scripts/rook/toolbox-connect.sh

##   rook.operator-logs    Print and continue following the Rook operator log.
rook.operator-logs:
	@ $(BASH) scripts/rook/follow-operator-log.sh

##   rook.restart-operator Restart the rook operator by deleting the pod.
rook.restart-operator:
	@ $(BASH) scripts/rook/restart-operator.sh

#
# Help
#
.PHONY: rook.help
# Use sed on this makefile to render all lines beginning with '##'
rook.help: scripts/rook/Makefile.help


rook.destroy-hook.%: rook.unset-config
	@ rm -f $(CURRENT_BUILT_BRANCH_FILE)
