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
CLUSTER_DATA ?= $(PWD)/.cluster
export NODE_LIST_FILE := $(CLUSTER_DATA)/node-list
export ANSIBLE_CONFIG ?= $(CLUSTER_DATA)/ansible.cfg

# kvmn = k8s-vagrant-multi-node
# make with --jobs option hangs standing up nodes in parallel?
.kvmn.%:
	@ mkdir -p $(CLUSTER_DATA)
	@ $(BASH_CMD) -c 'if ! git -C $(K8S_VAGRANT_DIR) status >/dev/null; then \
	    echo "  ERROR! k8s-vagrant-multi-node repo is not cloned to K8S_VAGRANT_DIR=$(K8S_VAGRANT_DIR); cannot continue!"; exit 1; fi'
	@ $(MAKE) --directory=$(K8S_VAGRANT_DIR) $*

##   cluster.build      Stand up a cluster for development with params defined in ${FIL}developer-settings${NON}
cluster.build: .kvmn.up
	@ $(MAKE) .kvmn.ssh-config > $(CLUSTER_DATA)/ssh_config
	@ sed -n -e 's/^Host //p' $(CLUSTER_DATA)/ssh_config > $(NODE_LIST_FILE)
	@ $(BASH_CMD) scripts/cluster/generate-ansible-cfg.sh > $(ANSIBLE_CONFIG)
	@ $(BASH_CMD) scripts/kubernetes/untaint-master.sh
	@ $(BASH_CMD) scripts/kubernetes/wait-for-up.sh
	@ $(BASH_CMD) scripts/kubernetes/verify.sh
	@ $(MAKE) cluster.setup

##   cluster.pause      Pause the previously-built developmet cluster.
cluster.pause: .kvmn.stop

##   cluster.unpause    Un-pause the previously-built development cluster.
cluster.unpause: .kvmn.up

##   cluster.destroy    Destroy the previously-built development cluster
cluster.destroy: .kvmn.clean .kvmn.clean-data .kvmn.clean-force
	@ rm -rf $(CLUSTER_DATA)
	@ $(MAKE) .rook.destroy-hook

##   cluster.push-image Push a local image ${ENV}IMG${NON} to the dev cluster's registry as ${ENV}TAG${NON}.
cluster.push-image:
	@ $(BASH_CMD) scripts/cluster/push-image.sh "$(IMG)" "$(TAG)"

##   cluster.ssh        SSH to the cluster master node as root.
cluster.ssh:
	@ ssh -F $(CLUSTER_DATA)/ssh_config -t master "sudo su -"

##   cluster.multi-ssh  Send SSH command ${ENV}CMD${NON} to node group ${ENV}GROUP${NON} (default ${ENV}GROUP=all${NON}).
GROUP ?= all
cluster.multi-ssh:
	@ $(MULTI_SSH) "$(GROUP)" "$(CMD)"

##   cluster.setup      Set up the cluster's basic user tooling like the remote registry.
cluster.setup:
	@ kubectl apply -f scripts/cluster/container-registry.yaml
# 	@ $(BASH_CMD) -c "chmod 600 scripts/resources/.ssh/id_rsa"
# 	@ $(BASH_CMD) scripts/cluster/wait-for-up.sh
# 	@ $(BASH_CMD) scripts/cluster/exercise-ssh.sh
# 	@ $(BASH_CMD) scripts/cluster/setup-bashrc.sh
# 	@ $(BASH_CMD) scripts/cluster/verify.sh

##
## KUBERNETES TARGETS
##   k8s.set-context    Set the kubectl context to the dev cluster.
k8s.set-context: .kvmn.kubectl-use-context

##   k8s.make-local-pvs Create Local PersistenVolumes for use in the cluster.
k8s.make-local-pvs:
	@ scripts/kubernetes/local-pv-create.sh

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
