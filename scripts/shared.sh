#!/usr/bin/env bash

# As a note, bash functions which return strings do so by echo'ing the result. When the function
# is called like 'var="$(fxn)"', var will get the return string. Trapping on ERR and returning
# the exit code will make the script exit as expected.
# Also use `set -Ee` with both upper- and lower-case E's
trap 'exit $?' ERR

#
# Rook
#

function get_operator_pod () {
  # grep 'Running' to easily avoid 'Terminating' bucket after forced operator restart
  kubectl --namespace "${ROOK_SYSTEM_NAMESPACE}" get pods --no-headers \
          --selector app=rook-ceph-operator | grep Running | awk '{print $1}'
}
export -f get_operator_pod

function get_toolbox_pod () {
  kubectl --namespace "${ROOK_NAMESPACE}" get pods \
          --selector app=rook-ceph-tools \
          --output custom-columns=name:metadata.name --no-headers
}
export -f get_toolbox_pod  # allow this to be used within suppress_output_unless_error

function exec_in_toolbox_pod () {
  kubectl --namespace "${ROOK_NAMESPACE}" exec "$(get_toolbox_pod)" -- \
    ${BASH_CMD} -c "$*"
}
export -f exec_in_toolbox_pod  # allow this to be used within suppress_output_unless_error


# Rook test pod
test_pod_name='rook-ceph-test'

function create_test_pod () {
  kubectl create -f scripts/rook/test-pod.yaml
}
export -f create_test_pod

function delete_test_pod () {
  kubectl delete -f scripts/rook/test-pod.yaml
}
export -f delete_test_pod

function get_test_pod () {
  kubectl --namespace rook-ceph get pods \
      --selector app="${test_pod_name}" \
      --output custom-columns=name:metadata.name --no-headers
}
export -f get_test_pod

function exec_in_test_pod () {
  kubectl --namespace rook-ceph exec "$(get_test_pod)" -- \
    ${BASH_CMD} -c "$*"
}
export -f exec_in_test_pod



#
# Misc functions
#
function suppress_output_unless_error () {
  local cmd="$1"
  if ! output="$(eval "$cmd" 2>&1)"; then
    echo "${output}"
    return 1
  fi
}
export -f suppress_output_unless_error

function wait_for () {
  local waiting_for="$1"  # reason
  local timeout="$2"  # in seconds
  local cmd="$3"
  msg="Waiting ${timeout} seconds for ${waiting_for} ..."
  echo -en "${msg} countdown: ${timeout}\r"
  output=""
  start_time=$SECONDS
  until output="$(${BASH_CMD} -c "${cmd}" 2>&1)" ; do
    if (( SECONDS - start_time > timeout )); then
      echo -e "\r${msg} countdown: 0 ... timed out! (output below)"
      echo "${output}"
      return 1
    fi
    echo -en "\r${msg} countdown: $((timeout - SECONDS + start_time)) "
    sleep 5
  done
  echo -e "\r${msg} countdown: $((timeout - SECONDS + start_time)) ... done after $((SECONDS - start_time)) seconds."
}
export -f wait_for
