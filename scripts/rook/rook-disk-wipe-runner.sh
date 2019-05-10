#!/usr/bin/env bash


# lvm vol groups and lvm logical volumes created for ceph can be found by paths in /dev
for vg in $(ls --directory /dev/ceph-*); do
  ( cd "$vg"
    for lv in *; do
      lvremove --yes "$vg/$lv"
    done
    vgremove --yes "$vg"
  )
done

# the boot disk isn't always sda or vda, and we CANNOT wipe the boot disk
boot_disk="$(fdisk --list | grep boot | grep --only-matching --extended-regexp /dev/[vs]d[a-z]+)"
rook_disks="$(find /dev -regex '/dev/[vs]d[a-z]+$' -and -not -wholename "${boot_disk}")"

# rook disks could be lvm physical volumes
for pv in ${rook_disks}; do
  pvremove --yes "$pv"
done

# zap the disks to a fresh, usable state after LVM info is delted
# (zap-all is important, b/c MBR has to be clean)
for disk in ${rook_disks}; do
  sgdisk --zap-all "${disk}"
done

# some devices might still be mapped that lock the disks
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
rm -rf /dev/mapper/ceph-*  # clutter

# ceph-volume setup also leaves ceph-UUID directories in /dev (just clutter)
rm -rf /dev/ceph-*
