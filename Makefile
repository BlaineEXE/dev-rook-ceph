include makelib.mk

# The theory behind makefile targets is that targets (or target groups) should not share the same
# 3 letters so tab complete is useful for the user. Ideally, the first 2 letters.

default:
	@ # Do nothing if make has no args

##
## CONFIGURATION
##   There are many environment variable-based tunable parameters for changing how the dev
##   environment is set up. These defaults can be found in `_default-dev-settings`. It is intended
##   that the user can provide their own overrides in the `developer-settings` file.


##
## QUICKSTART
##   quickstart         Perform all steps to set up a Kubernetes cluster ready for Rook development
quickstart:
	@ $(MAKE) cluster.build cluster.setup kubernetes.install

##
## CLUSTER TARGETS
##   cluster.build      Stand up a cluster for development with params defined in 'developer-settings'
cluster.build:
	@ $(SUDO) $(PYTHON) scripts/libvirt/apply.py
	@ $(SUDO) $(PYTHON) scripts/libvirt/generate-node-list.py

##   cluster.destroy    Destroy a previously-built development cluster
cluster.destroy:
	@ NUM_MASTERS=0 NUM_WORKERS=0 $(SUDO) $(PYTHON) scripts/libvirt/apply.py
	@ rm -f _node-list
	@ rm -f $(KUBECONFIG)
	@ $(MAKE) rook.destroy-hook.%

##   cluster.setup      Set up the cluster's basic tooling
cluster.setup: $(OCTOPUS_TOOL)
	@ $(BASH) scripts/cluster/wait-for-up.sh
	@ $(BASH) scripts/cluster/config-octopus.sh
	@ $(BASH) scripts/cluster/copy-octopus-to-cluster.sh
	@ $(BASH) scripts/cluster/install-dependencies.sh
	@ $(BASH) scripts/cluster/set-iptables-permissive.sh
	@ $(BASH) scripts/cluster/exercise-ssh.sh
	@ $(BASH) scripts/cluster/setup-bashrc.sh
	@ # reboot?
	@ $(BASH) scripts/cluster/verify.sh


##
## KUBERNETES TARGETS
##   kubernetes.install Install Kubernetes on the cluster with params defined in 'developer-settings'
kubernetes.install: $(OCTOPUS_TOOL)
	@ $(BASH) scripts/kubernetes/install-kubeadm.sh
	@ $(BASH) scripts/kubernetes/install-k8s.sh
	@ $(BASH) scripts/kubernetes/wait-for-up.sh
	@ $(BASH) scripts/kubernetes/untaint-master.sh
	@ $(BASH) scripts/kubernetes/verify.sh


##
## ROOK TARGETS
##   rook.help          Show all Rook targets
export ROOK_SYSTEM_NAMESPACE ?= rook-ceph-system
export ROOK_NAMESPACE ?= rook-ceph
include scripts/rook/Makefile


##
## CEPH TARGETS
##   (not yet implemented)


# call.script.% SCRIPT=<script-path> - to call a single script with make's env vars set up
call.script.%:
	@ $(BASH) $(SCRIPT)

#
# Help
#
.PHONY: help
# Use sed on this makefile to render all lines beginning with '##'
help: Makefile
	@ sed -n 's/^##//p' $<

##
