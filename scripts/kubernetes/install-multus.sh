#!/usr/bin/env bash

# download the multus daemonset, and remove mem and cpu limits
curl https://raw.githubusercontent.com/k8snetworkplumbingwg/multus-cni/master/deployments/multus-daemonset-thick-plugin.yml \
  | sed -e 's/cpu: /# cpu: /g' -e 's/memory: /# memory: /g' \
  | kubectl apply -f -

# install whereabouts
kubectl apply \
  -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/master/doc/crds/daemonset-install.yaml \
  -f https://raw.githubusercontent.com/k8snetworkplumbingwg/whereabouts/master/doc/crds/ip-reconciler-job.yaml \
  -f https://github.com/k8snetworkplumbingwg/whereabouts/raw/master/doc/crds/whereabouts.cni.cncf.io_ippools.yaml \
  -f https://github.com/k8snetworkplumbingwg/whereabouts/raw/master/doc/crds/whereabouts.cni.cncf.io_overlappingrangeipreservations.yaml

# install networks
kubectl create namespace rook-ceph || true
kubectl apply -f - <<EOF
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: public-net
  namespace: rook-ceph
  labels:
  annotations:
spec:
  config:  '{ "cniVersion": "0.3.0", "type": "macvlan", "master": "eth0", "mode": "bridge", "ipam": { "type": "whereabouts", "range": "192.168.20.0/24" } }'
---
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: cluster-net
  namespace: rook-ceph
  labels:
  annotations:
spec:
  config:  '{ "cniVersion": "0.3.0", "type": "macvlan", "master": "eth0", "mode": "bridge", "ipam": { "type": "whereabouts", "range": "192.168.21.0/24" } }'
EOF
