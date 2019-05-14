#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh
echo ''
echo 'SETTING UP CEPHFS AND INSTALLING MDSES'
( cd ${ROOK_CONFIG_DIR}/ceph
  kubectl create -f filesystem.yaml
)

# Wait for 2 mdses to start
wait_for "mdses to start" 60 \
  "kubectl get --namespace ${ROOK_NAMESPACE} pods | grep -q 'rook-ceph-mds-myfs-b.*Running'"

# Test the FS in a mon pod
toolbox_pod="$(get_toolbox_pod)"

wait_for "myfs to be active" 60 \
  "exec_in_toolbox_pod 'ceph fs status myfs 2>&1 | grep -q active' &> /dev/null"
  # must use 'bash -c "...stuff..."' to use pipes within kubectl exec
  # for whatever reason, 'ceph fs status' returns info on stderr ... ?
  # above will print 'command terminated with exit code #' if stderr isn't sent to /dev/null

echo ''
echo 'SMOKE TESTING CEPHFS'


# Mount the FS in the tools container, create a file, then unmount and exit
kubectl exec -n "${ROOK_NAMESPACE}" "${toolbox_pod}" -- bash ${BASHFLAGS:=} -c "$(cat <<'EOF'
# Create dir for our
mkdir /tmp/cephfs

# Detect the mon endpoints and the user secret for the connection
mon_endpoints=$(grep 'mon.host' /etc/ceph/ceph.conf | awk '{print $NF}')
my_secret=$(grep key /etc/ceph/keyring | awk '{print $NF}')

# Mount the file system
mount -t ceph -o mds_namespace=myfs,name=admin,secret=$my_secret $mon_endpoints:/ /tmp/cephfs

# See your mounted file system
df -h /tmp/cephfs

echo "Hello Rook" > /tmp/cephfs/hello

umount /tmp/cephfs
rmdir /tmp/cephfs
EOF
)"

# Mount the FS in the tools container again, see that the file exits w/ the right info
kubectl exec -n "${ROOK_NAMESPACE}" "${toolbox_pod}" -- bash ${BASHFLAGS:=} -c "$(cat <<'EOF'
# Create dir for our
mkdir /tmp/cephfs

# Detect the mon endpoints and the user secret for the connection
mon_endpoints=$(grep 'mon.host' /etc/ceph/ceph.conf | awk '{print $NF}')
my_secret=$(grep key /etc/ceph/keyring | awk '{print $NF}')

# Mount the file system
mount -t ceph -o mds_namespace=myfs,name=admin,secret=$my_secret $mon_endpoints:/ /tmp/cephfs

cat /tmp/cephfs/hello

umount /tmp/cephfs
rmdir /tmp/cephfs
EOF
)" | tee /tmp/.start-file-results.txt

if [ ! "$(cat /tmp/.start-file-results.txt)" = "Hello Rook" ]; then
  echo "  Ceph filesystem does not seem to be persistent!"
  exit 1
fi
echo "  Ceph filesystem smoke tested ok!"
