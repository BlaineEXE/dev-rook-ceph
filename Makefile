include .makelib.mk

# Make sure git doesn't track others' changes to developer-settings
$(shell git update-index --assume-unchanged developer-settings)

# The theory behind makefile targets is that targets (or target groups) should not share the same
# 3 letters so tab complete is useful for the user. Ideally, the first 2 letters.

.DEFAULT_GOAL := help

##
## CONFIGURATION
##  There are many tunable parameters for changing how the dev cluster/environment is set up.
##  Configuration is not requred, as sensible default values are already applied. If desired, the user
##  should set their configuration overrides in the ${FIL}developer-settings${NON} file.


##
## CLUSTER TARGETS
K8S_VAGRANT_DIR ?= $(PWD)/k8s-vagrant-multi-node

# kvmn = k8s-vagrant-multi-node
# hangs executing in parallel?
.kvmn.%:
	@ [[ -z "$(DEBUG)" ]] || env
	@ $(MAKE) --directory=$(K8S_VAGRANT_DIR) $*

##   cluster.build      Stand up a cluster for development with params defined in ${FIL}developer-settings${NON}
cluster.build: .kvmn.up
	@ $(BASH_CMD) scripts/kubernetes/untaint-master.sh
	@ $(BASH_CMD) scripts/kubernetes/wait-for-up.sh
	@ $(BASH_CMD) scripts/kubernetes/verify.sh

##   cluster.pause      Pause the previously-built developmet cluster.
cluster.pause: .kvmn.stop

##   cluster.destroy    Destroy the previously-built development cluster
cluster.destroy: .kvmn.clean .kvmn.clean-data .kvmn.clean-force
	@ $(MAKE) .rook.destroy-hook

##   cluster.push-image Push a local image ${ENV}IMG${NON} to the dev cluster [optional: as tag ${ENV}TAG${NON}]
cluster.push-image: .kvmn.load-image

##   cluster.ssh        SSH to the cluster master node
cluster.ssh: .kvmn.ssh-master

# ##   cluster.setup      Set up the cluster's basic user tooling
# cluster.setup: $(OCTOPUS_TOOL)
# 	@ $(BASH_CMD) -c "chmod 600 scripts/resources/.ssh/id_rsa"
# 	@ $(BASH_CMD) scripts/cluster/config-octopus.sh
# 	@ $(BASH_CMD) scripts/cluster/wait-for-up.sh
# 	@ $(BASH_CMD) scripts/cluster/copy-octopus-to-cluster.sh
# 	@ $(BASH_CMD) scripts/cluster/exercise-ssh.sh
# 	@ $(BASH_CMD) scripts/cluster/setup-bashrc.sh
# 	@ $(BASH_CMD) scripts/cluster/verify.sh


##
## ROOK TARGETS
##   rook.help          Show all Rook targets
export ROOK_SYSTEM_NAMESPACE ?= rook-ceph
export ROOK_NAMESPACE ?= rook-ceph
include scripts/rook/Makefile


##
## CEPH TARGETS
##   ceph.help          Show all Ceph targets
include scripts/ceph/Makefile

##
## UPGRADE TARGETS
##   upgrade.help       Show all upgrade targets
include scripts/upgrade/Makefile


##
## ADVANCED
##  Set ${ENV}DEBUG=1${NON} when using ${CMD}make${NON} to run dev env scripts with additional debug output.

# .call.script SCRIPT=<script-path> - to call a single script with make's env vars set up
.call.script:
	@ $(BASH_CMD) $(SCRIPT)

#
# Help
#
.PHONY: help
# Use sed on this makefile to render all lines beginning with '##'
help: Makefile.help
