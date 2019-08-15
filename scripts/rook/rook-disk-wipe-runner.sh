#!/usr/bin/env bash
set -Eeuo pipefail

# # lvm vol groups and lvm logical volumes created for ceph can be found by paths in /dev
# vgscan
# lvscan
# for lv in $(lvs | grep osd); do
#   # ???: lvremove --yes $lv
# done
# for vg in $(vgs | grep ceph); do
#   # ???: vgremove --yes $vg
# done
# # for vg in $(ls --directory /dev/ceph-*); do
# #   ( cd "$vg"
# #     for lv in *; do
# #       lvremove --yes "$vg/$lv"
# #     done
# #     vgremove --yes "$vg"
# #   )
# # done

# # rook disks could be lvm physical volumes
# for pv in ${rook_disks}; do
#   pvremove --yes "$pv"
# done

# # some devices might still be mapped that lock the disks
# ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
# rm -rf /dev/mapper/ceph-*  # clutter
if dmsetup status | grep ceph; then
  dmstatus="$(dmsetup status | grep ceph)"
  for statusline in $dmstatus; do
    device_with_colon="${statusline%%\ *}" # the first 'word' is the device with a colon after it
    device="${device_with_colon%%:}" # remove the colon
    dmsetup remove "${device}"
    rm -f /dev/mapper/"${device}"
  done

  # ceph-volume setup also leaves ceph-UUID directories in /dev that eventually point to dm devices
  rm -rf /dev/ceph-*
fi

# the boot disk isn't always sda or vda, and we CANNOT wipe the boot disk
boot_disk="$(fdisk --list | grep boot | grep --only-matching --extended-regexp /dev/[vs]d[a-z]+)"
rook_disks="$(find /dev -regex '/dev/[vs]d[a-z]+$' -and -not -wholename "${boot_disk}")"

# zap the disks to a fresh, usable state after LVM info is delted
# (zap-all is important, b/c MBR has to be clean)
for disk in ${rook_disks}; do
  sgdisk --zap-all "${disk}"
done
