#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh
source _node-list

kube_setup_dir="/root/.setup-kube"

echo "Installing Kubernetes ${K8S_VERSION} ..."

echo "  copying config files to cluster ..."
suppress_output_unless_error \
  "${OCTOPUS} --host-groups all          copy scripts/kubernetes/KUBELET_EXTRA_ARGS /root"
suppress_output_unless_error \
  "${OCTOPUS} --host-groups first_master copy scripts/kubernetes/kubeadm-init-config.yaml \
                                              scripts/kubernetes/cluster-psp.yaml         \
                                           ${kube_setup_dir}"

echo "  running 'kubeadm init' on first master ..."
# init config file has extra API server args to enable psp access control
init_command="kubeadm init --config=${kube_setup_dir}/kubeadm-init-config.yaml"
# for idempotency, do not run init if docker is already running kube resources
suppress_output_unless_error "${OCTOPUS} --host-groups first_master run \
  'if ! docker ps -a | grep -q kube; then ${init_command} ; fi'"

echo "  setting up root user on first master as Kubernetes administrator ..."
suppress_output_unless_error "${OCTOPUS} --host-groups first_master run \
  'mkdir -p /root/.kube && ln -f -s /etc/kubernetes/admin.conf /root/.kube/config'"
suppress_output_unless_error "${OCTOPUS} --host-groups first_master run \
  'kubectl completion bash > ~/.kube/kubectl-completion.sh && chmod +x ~/.kube/kubectl-completion.sh'"

echo "  setting up default cluster pod security policies (PSPs) ..."
suppress_output_unless_error "${OCTOPUS} --host-groups first_master run \
  'kubectl apply -f ${kube_setup_dir}/cluster-psp.yaml'"

echo "  setting up cluster overlay network CNI ..."
# Cilium runs its own etcd which we want to be able to run on the master
first_master_hostname="$("${BASH}" ./ssh-to-cluster.sh hostname)"
first_master_hostname="${first_master_hostname%$'\r'}" # comes back with \r on the end
suppress_output_unless_error "${OCTOPUS} --host-groups first_master run \
   'kubectl taint node ${first_master_hostname} node-role.kubernetes.io/master:NoSchedule-'"

suppress_output_unless_error "${OCTOPUS} --host-groups first_master run \
   'kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.5/examples/kubernetes/1.14/cilium.yaml'"
#'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml'"

# echo "  joining remaining master nodes to Kubernetes cluster ..."
# join_command="??????"
# ${OCTOPUS} --host-groups noninitial_masters run "${join_command}"

echo "  joining worker nodes to Kubernetes cluster ..."
join_command="$(${OCTOPUS} --host-groups first_master run \
                  'kubeadm token create --print-join-command' | grep 'kubeadm join')"
# for idempotency, do not run init if docker is already running kube resources
suppress_output_unless_error "${OCTOPUS} --host-groups workers run \
  'if ! docker ps -a | grep -q kube; then ${join_command} ; fi'"

echo "... done."
