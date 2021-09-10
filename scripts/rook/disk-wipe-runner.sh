#!/usr/bin/env bash
set -Eeuo pipefail

# remove encryped LVM devices
# remove dm devices twice; first pass removes sub-devices
dms="$(dmsetup ls | awk '{print $1}')"
for dm in $dms; do
  dmsetup remove "$dm" || true
done
dms="$(dmsetup ls | awk '{print $1}')"
for dm in $dms; do
  dmsetup remove "$dm" || true
done

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

if [[ "$(hostname)" == minikube* ]]; then
  # on minikube, boot disk is reliably vda or sda
  boot_disk="$(lsblk --output KNAME | grep -E '[sv]da$')"
else
  # the boot disk isn't always sda or vda, and we CANNOT wipe the boot disk
  # if there are partitions, we want to wipe those first
  # grep flags: -o == --only-matching, -E == --extended-regexp, -v == --invert-match
  boot_disk="$(fdisk --list | \
    grep -E '(boot|/dev/.*\*)' | \
    grep -o -E '/dev/[vs]d[a-z]+')"
fi
lsblk_cmd='lsblk --noheadings --paths --output KNAME'
# lsblk --nodeps gives only disks, --inverse with --nodeps gives only partitions
rook_partitions="$(${lsblk_cmd} --inverse --nodeps | grep -E '/dev/[vs]d[a-z]+' | grep -v "${boot_disk}")"
rook_disks="$(${lsblk_cmd} --nodeps | grep -E '/dev/[vs]d[a-z]+' | grep -v "${boot_disk}")"
rook_devices="${rook_partitions} ${rook_disks}"

# zap the device to a fresh, usable state after LVM info is delted
# (zap-all is important, b/c MBR has to be clean)
for device in ${rook_devices}; do
  # wipefs --all "${device}" # not avail on minikube
  # lvm metadata can be a lot of sectors
  dd if=/dev/zero of="${device}" bs=512 count=10000
  # sgdisk --zap-all "${device}"
done

# some devices might still be mapped that lock the disks
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove --force % || true
rm -rf /dev/mapper/ceph-*  # clutter

# ceph-volume setup also leaves ceph-UUID directories in /dev (just clutter)
rm -rf /dev/ceph-*
