# The theory behind makefile targets is that targets (or target groups) should not share the same
# 3 letters so tab complete is useful for the user. Ideally, the first 2 letters.

##
## ROOK TARGET USAGE
##   A good pattern for Rook development is to keep 2 (or more) branches:
##     1. a "config branch" with kubernetes manifest files edited to install Rook in your cluster
##          Manifest files are in    cluster/examples/kubernetes/ceph/
##          The master branch is a good default for installing in CaaSP clusters
##     2. a working branch with your Rook code changes
##          This is where your Rook changes live without needing to have manifest files modified
##
##   Using this pattern, a good dev workflow for Rook code is:
##     1. Copy Rook's Kubernetes install config         make rook.copy-config   (from config branch)
##     2. Build and push Rook images to hosts           make rook.build        (from working branch)
##     3. Install Rook                                  make rook.install          (from any branch)
##     4. Uninstall Rook before using a new config      make rook.uninstall        (from any branch)

# Targets followed by '%' are hidden from make's tab complete. These targets can be called via
# `make target.%`; however, this is an advanced usage not documented in the help text.
# Run a Rook make target with only the Ceph backend

ROOK_REPO_DIR ?= $(GOPATH)/src/github.com/rook/rook
ROOK_CONFIG_DIR ?= $(PWD)/.rook-config

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

##
##   rook.copy-config      Copy the current Rook branch's config files to '.rook-config/'. This allows
##                         you to have a consistent Rook config after branch changes.
CURRENT_CONFIG_BRANCH_FILE := $(ROOK_CONFIG_DIR)/_current-config-branch
$(CURRENT_CONFIG_BRANCH_FILE): rook.symlink.%
	@ printf '  WARNING! There is no record of a config branch selected for use'
	@ printf '  using configs from the current branch: %s\n' "$$(git -C rook/ rev-parse --abbrev-ref HEAD)"
	@ mkdir -p $(ROOK_CONFIG_DIR)
	@ cp -a rook/cluster/examples/kubernetes/* $(ROOK_CONFIG_DIR)/.
# don't store the current branch in this case so the behavior continues to be the same
# Print the current config branch for the user to see
rook.print-config-branch.%:
	@ echo "  CURRENT CONFIG BRANCH: $$(cat $(CURRENT_CONFIG_BRANCH_FILE) 2> /dev/null)"
rook.copy-config: rook.symlink.%
	@ mkdir -p $(ROOK_CONFIG_DIR)
	@ cp -a rook/cluster/examples/kubernetes $(ROOK_CONFIG_DIR)/.
	@ git -C rook/ rev-parse --abbrev-ref HEAD > $(CURRENT_CONFIG_BRANCH_FILE)
	@ $(MAKE) rook.showinfo

##
##   rook.build            Build Rook locally, and push the Rook image to nodes as 'rook/rook:master'
CURRENT_BUILT_BRANCH_FILE := scripts/rook/_current-built-branch
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

##
##   rook.install          Install Rook on the cluster with the config files set up via
##                         'rook.copy-config'. Uses the current branch's config if copy-config
##                         target hasn't been called.
rook.install: $(CURRENT_CONFIG_BRANCH_FILE)
	@ $(BASH) scripts/rook/install.sh
	@ $(BASH) scripts/rook/install-filesystem.sh
	@ $(BASH) scripts/resources/success-message.sh "ROOK INSTALLED"
	@ $(MAKE) rook.showinfo

##
##   rook.uninstall        Uninstall Rook from the cluster with the config files set via
##                         'rook.copy-config'. Run this target before copying new configs.
rook.uninstall: $(CURRENT_CONFIG_BRANCH_FILE)
	@ $(BASH) scripts/rook/uninstall.sh
	@ $(MAKE) rook.showinfo
	@ sleep 10  # I think k8s needs time to flush the info from etcd
	@ $(BASH) scripts/resources/success-message.sh "ROOK UN-INSTALLED"

##
##   rook.reinstall        Uninstall and then re-install Rook with the same config and image.
rook.reinstall: rook.uninstall rook.install

##
##   rook.replace          Rebuild without reinstalling the cluster. When the image is built and
##                         pushed, the operator pod is restarted to run the new version. Useful for
##                         quickly iterating on Rook code changes.
rook.replace: rook.build
	@ $(BASH) scripts/rook/replace-operator.sh"
	@ $(MAKE) rook.showinfo
	@ bash scripts/resources/success-message.sh "ROOK IS REBUILT IN-PLACE"

##
##   rook.rebuild          Uninstall and build Rook, and then install Rook again with the same config.
##                         Useful in cases where rook.replace is insufficient.
rook.rebuild:
	@ # Uninstall and buildpush can be done in parallel; the rest must come after build
	@ $(MAKE) --jobs rook.uninstall rook.build
	@ $(MAKE) rook.install
	@ $(MAKE) rook.showinfo
	@ bash scripts/resources/success-message.sh "ROOK IS REBUILT AND REINSTALLED"

##
##   rook.reconfig         Uninstall Rook cluster, then install Rook again with the current config
##                         and with the same Rook images. Useful for iterating on Rook config changes.
rook.reconfig: rook.uninstall rook.copy-config rook.install rook.showinfo
	@ bash scripts/resources/success-message.sh "ROOK IS REINSTALLED WITH A NEW CONFIG"

##
##   rook.test             Run unit tests on Rook.
rook.test: rook.make.test
	@ bash scripts/resources/success-message.sh "ROOK UNIT TESTS PASSED"

##
##   rook.show-info        Print info about the current Rook install/config.
rook.showinfo:
	@ echo ''
	@ $(MAKE) rook.print-config-branch.%
	@ $(MAKE) rook.print-built-branch.%
	@ echo ''

##
##
## ROOK DEV TOOLS
##
##   rook.toolbox-connect  Connect to the Rook toolbox.
rook.toolbox-connect:
	@ $(BASH) scripts/rook/toolbox-connect.sh

##   rook.operator-logs    Print the Rook operator log, and continue to follow the log.
rook.operator-logs:
	@ $(BASH) scripts/rook/follow-operator-log.sh

#
# Help
#
.PHONY: rook.help
# Use sed on this makefile to render all lines beginning with '##'
rook.help: scripts/rook/Makefile
	@ sed -n 's/^##//p' $<

##

rook.destroy-hook.%:
	@ rm -f CURRENT_BUILT_BRANCH_FILE
	@ rm -rf $(ROOK_CONFIG_DIR) # contains CURRENT_CONFIG_BRANCH_FILE
