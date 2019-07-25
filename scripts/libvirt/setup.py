#!/usr/bin/env python3

import cloudconfig
import network
import node
import os
import sys
import virsh

from variables import *

#
# determine desired cluster config
#

if NUM_MASTERS > 1:
    print("Only one master is currently supported: NUM_MASTERS=" + NUM_MASTERS)
    exit(1)

# download the os image to the download pool
osImageName = virsh.DownloadImageToVolume(LIBVIRT_URI, NODE_OS_IMAGE, LIBVIRT_IMAGE_DOWNLOAD_POOL)


#
# networks
#

if CLUSTER_PREFIX.startswith('-'):
    # libvirt dnsmasq does not allow the domain to start with a '-' char
    print("CLUSTER_PREFIX cannot start with a '-' char", file=sys.stderr)
    exit(1)

FULL_NET_DOMAIN_NAME = CLUSTER_PREFIX + NET_DOMAIN_NAME

k8sNet = network.LvmNetwork( # k8s network / main network
    networkName=FULL_NET_DOMAIN_NAME, domainName=FULL_NET_DOMAIN_NAME, networkWithCIDR=NET_CIDR)


#
# nodes
#

# all nodes have the same config
hwConfig = node.HardwareConfig(cpus=NODE_VCPUS, ram_MB=NODE_RAM_MB)
osConfig = node.OSConfig(parentImage=osImageName, parentImagePool=LIBVIRT_IMAGE_DOWNLOAD_POOL,
                            createdDiskPool=LIBVIRT_OS_VOL_POOL, minSizeGB=NODE_MIN_OS_DISK_SIZE)
volConfig = node.VolumeConfig(count=NODE_ROOK_VOLUMES, sizeGB=NODE_ROOK_VOLUME_SIZE_GB, pool=LIBVIRT_ROOK_VOL_POOL)
netConfigs = [ node.NetworkConfig(k8sNet.networkName) ]

# set up nodes
nodes = []
if NUM_MASTERS > 0:
    # set up master node configs
    for i in range(NUM_MASTERS):
        n = node.LvmDomain(CLUSTER_PREFIX + "k8s-master-" + str(i), hwConfig, osConfig, volConfig, netConfigs)
        nodes = nodes + [n]
    # set up worker node configs
    for i in range(NUM_WORKERS):
        n = node.LvmDomain(CLUSTER_PREFIX + "k8s-worker-" + str(i), hwConfig, osConfig, volConfig, netConfigs)
        nodes = nodes + [n]


if len(nodes) > 0:
    print("\n")
    print("PLANNED RESOURCES:")
    print(k8sNet)
    for n in nodes:
        print(n)
    print("\n")


# works on nodes and volumes, not networks
def resourceBelongsToThisCluster(resourceName):
    return CLUSTER_PREFIX+"k8s-master-" in resourceName \
        or CLUSTER_PREFIX+"k8s-worker-" in resourceName \
        or FULL_NET_DOMAIN_NAME in resourceName
