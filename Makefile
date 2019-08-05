include makelib.mk

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
## QUICKSTART
##   quickstart         Perform all steps to set up a Kubernetes cluster ready for Rook development
##                          with params defined in ${FIL}developer-settings${NON}
quickstart:
	@ $(MAKE) cluster.build cluster.setup kubernetes.install

##
## CLUSTER TARGETS
##   cluster.build      Stand up a cluster for development with params defined in ${FIL}developer-settings${NON}
cluster.build:
	@ $(SUDO) $(PYTHON) scripts/libvirt/apply.py
	@ $(SUDO) $(PYTHON) scripts/libvirt/generate-node-list.py

##   cluster.destroy    Destroy a previously-built development cluster
cluster.destroy:
	@ NUM_MASTERS=0 NUM_WORKERS=0 $(SUDO) $(PYTHON) scripts/libvirt/apply.py
	@ rm -f _node-list
	@ rm -f $(KUBECONFIG)
	@ $(MAKE) rook.destroy-hook.%

##   cluster.setup      Set up the cluster's basic user tooling
cluster.setup: $(OCTOPUS_TOOL)
	@ $(BASH) -c "chmod 600 scripts/resources/.ssh/id_rsa"
	@ $(BASH) scripts/cluster/config-octopus.sh
	@ $(BASH) scripts/cluster/wait-for-up.sh
	@ $(BASH) scripts/cluster/copy-octopus-to-cluster.sh
	@ $(BASH) scripts/cluster/install-dependencies.sh
	@ $(BASH) scripts/cluster/set-iptables-permissive.sh
	@ $(BASH) scripts/cluster/exercise-ssh.sh
	@ $(BASH) scripts/cluster/setup-bashrc.sh
	@ $(BASH) scripts/cluster/verify.sh


##
## KUBERNETES TARGETS
##   kubernetes.install Install Kubernetes on the cluster with params defined in ${FIL}developer-settings${NON}
kubernetes.install: $(OCTOPUS_TOOL)
	@ $(BASH) scripts/kubernetes/install-kubeadm.sh
	@ $(BASH) scripts/kubernetes/install-k8s.sh
	@ $(BASH) scripts/kubernetes/download-kubeconfig.sh
	@ $(BASH) scripts/kubernetes/wait-for-up.sh
	@ $(BASH) scripts/kubernetes/untaint-master.sh
	@ $(BASH) scripts/kubernetes/verify.sh

##   kubernetes-dashboard.install Install kubernetes-dashboard on the cluster with params defined in ${FIL}developer-settings${NON}
kubernetes-dashboard.install:
	@ $(BASH) scripts/kubernetes/install-dashboard.sh

##   kubernetes-dashboard.fwd    Port forward the kubernetes-dashboard service to localhost.
kubernetes-dashboard.fwd:
	@ $(BASH) scripts/kubernetes/dashboard-port-forward.sh


##
## ROOK TARGETS
##   rook.help          Show all Rook targets
export ROOK_SYSTEM_NAMESPACE ?= rook-ceph
export ROOK_NAMESPACE ?= rook-ceph
include scripts/rook/Makefile


##
## CEPH TARGETS
##   [not yet implemented]

##
## UPGRADE TARGETS
##   upgrade.help       Show all upgrade targets
include scripts/upgrade/Makefile


# call.script.% SCRIPT=<script-path> - to call a single script with make's env vars set up
call.script.%:
	@ $(BASH) $(SCRIPT)

#
# Help
#
.PHONY: help
# Use sed on this makefile to render all lines beginning with '##'
help: Makefile.help
