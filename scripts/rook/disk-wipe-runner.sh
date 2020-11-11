#!/usr/bin/env bash
set -Eeuo pipefail

vgimport -a || true
# list all vgs
for vg in $(vgs --noheadings --readonly --separator=' ' -o vg_name); do
  lvremove --yes --force "$vg"
  vgremove --yes --force "$vg"
done
# list all pvs
for pv in $(pvs --noheadings --readonly --separator=' ' -o pv_name); do
  pvremove --yes --force "$pv"
done

# the boot disk isn't always sda or vda, and we CANNOT wipe the boot disk
boot_disk="$(fdisk --list | \
  grep --extended-regexp '(boot|/dev/.*\*)' | \
  grep --only-matching --extended-regexp '/dev/[vs]d[a-z]+')"
ls /dev/s*
rook_disks="$(find /dev -regex '/dev/[vs]d[a-z]+$' -and -not -wholename "${boot_disk}")"

# zap the disks to a fresh, usable state after LVM info is delted
# (zap-all is important, b/c MBR has to be clean)
for disk in ${rook_disks}; do
  wipefs --all "${disk}"
  # lvm metadata can be a lot of sectors
  dd if=/dev/zero of="${disk}" bs=512 count=10000
  # sgdisk --zap-all "${disk}"
done

# some devices might still be mapped that lock the disks
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove --force % || true
rm -rf /dev/mapper/ceph-*  # clutter

# ceph-volume setup also leaves ceph-UUID directories in /dev (just clutter)
rm -rf /dev/ceph-*
