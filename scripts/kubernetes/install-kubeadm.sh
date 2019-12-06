#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh
source _node-list

echo "Installing kubeadm components ..."


echo "  starting required IPVS kernel modules ..."
# required for k8s to use the "IPVS proxier"
suppress_output_unless_error "${OCTOPUS} --host-groups all run \
    'modprobe ip_vs ; modprobe ip_vs_rr ; modprobe ip_vs_wrr ; modprobe ip_vs_sh'"

echo "  downloading and installing crictl ..."
# kubeadm uses crictl to talk to docker/crio
CRICTL_VERSION=v1.16.0
suppress_output_unless_error "${OCTOPUS} --host-groups all run '\
    rm -f crictl-${CRICTL_VERSION}-linux-amd64.tar.gz*
    wget https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    tar -C /usr/bin -xf crictl-${CRICTL_VERSION}-linux-amd64.tar.gz && \
    chmod +x /usr/bin/crictl && \
    rm crictl-${CRICTL_VERSION}-linux-amd64.tar.gz'"

echo "  downloading and installing kubeadm binaries ..."
for binary in kubeadm kubectl kubelet; do
    suppress_output_unless_error "${OCTOPUS} --host-groups all run '\
        curl -LO https://storage.googleapis.com/kubernetes-release/release/${K8S_VERSION}/bin/linux/amd64/${binary} && \
        chmod +x ${binary} && mv ${binary} /usr/bin'"
done

echo "  downloading and installing CNI plugins ..."
# CNI plugins are required for most network addons
# https://github.com/containernetworking/plugins/releases
CNI_VERSION=v0.7.5
suppress_output_unless_error "${OCTOPUS} --host-groups all run '\
    rm -f cni-plugins-amd64-${CNI_VERSION}.tgz*
    wget https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz && \
    mkdir -p /opt/cni/bin && \
    tar -C /opt/cni/bin -xf cni-plugins-amd64-${CNI_VERSION}.tgz && \
    rm cni-plugins-amd64-${CNI_VERSION}.tgz'"

echo "  setting up kubelet service ..."
suppress_output_unless_error \
    "${OCTOPUS} --host-groups all copy scripts/kubernetes/kubelet.service /usr/lib/systemd/system"
suppress_output_unless_error \
    "${OCTOPUS} --host-groups all run 'systemctl enable kubelet'"

echo "  disabling apparmor ..."
suppress_output_unless_error \
    "${OCTOPUS} --host-groups all run 'systemctl disable apparmor --now || true'"

echo "... done."
