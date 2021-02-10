#!/usr/bin/env bash
set -eEuo pipefail

function render_local_pv() {
  local disk_name="$1"
  local disk_path="$2"
  local size_bytes="$3"
  local hostname="$4"
  cat <<EOF
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-${hostname}-${disk_name}
  labels:
    type: local
spec:
  storageClassName: local
  capacity:
    storage: ${size_bytes}
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  volumeMode: Block
  local:
    path: "${disk_path}"
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
              - "${hostname}"
EOF
}

hostname="$(hostname --short)"

# --nodeps won't print partitions or LVM info
disks="$(lsblk --output=NAME,PATH,TYPE,SIZE,PTUUID --bytes --nodeps --noheadings --list)"
echo "${disks}" | while read -ra line; do
  name="${line[0]}"
  path="${line[1]}"
  type="${line[2]}"
  size_bytes="${line[3]}"
  # PTUUID will only be present for disks with a partition table. If disks are wiped clean,
  # only the boot disk should have PTUUID.

  if [[ "${type}" != "disk" ]]; then
    >&2 echo "not creating Local PersistentVolume for device ${name} that is not a disk"
  fi
  if [[ "${#line[@]}" -gt 4 ]]; then
    >&2 echo "not creating Local PersistentVolume for disk ${name} with a partition"
    continue
  fi

  >&2 echo "creating Local PersistentVolume manifest for disk ${name}"
  render_local_pv "${name}" "${path}" "${size_bytes}" "${hostname}"
done
