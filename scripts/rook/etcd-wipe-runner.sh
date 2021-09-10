#!/usr/bin/env bash
set -Eeuo pipefail

# get etcd container id (must not be a pause container, which is probably a Pod)
etcd_ps="$(docker ps -a | grep etcd | grep -v pause)"
etcd_ctr_id="${etcd_ps%% *}" # container id is first word in line

cert_dir="/etc/kubernetes/pki" # for kubeadm
if [[ "$(hostname)" == minikube* ]]; then
  cert_dir="/var/lib/minikube/certs"
fi

etcd_ctr_exec="docker exec ${etcd_ctr_id}"
etcdctl_cmd="ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cert=${cert_dir}/etcd/server.crt \
  --key=${cert_dir}/etcd/server.key \
  --cacert=${cert_dir}/etcd/ca.crt"

resources="$(${etcd_ctr_exec} sh -c "${etcdctl_cmd} get / --prefix --keys-only")"
for resource in ${resources}; do
  if [[ "${resource}" =~ "rook" ]] \
       || [[ "${resource}" =~ "ceph" ]] \
       || [[ "${resource}" =~ "rbd" ]]; then
    echo "Deleting ETCD resource ${resource}..."
    ${etcd_ctr_exec} sh -c "${etcdctl_cmd} del ${resource}"
    echo "done."
  fi
done
