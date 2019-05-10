import os


#
# variables
#

# this can be set to allow multiple clusters on one URI without collisions
CLUSTER_PREFIX = os.getenv("CLUSTER_PREFIX", "")

LIBVIRT_URI                 = os.getenv("LIBVIRT_URI", "qemu:///system")
LIBVIRT_IMAGE_DOWNLOAD_POOL = os.getenv("LIBVIRT_IMAGE_DOWNLOAD_POOL", "default")
LIBVIRT_OS_VOL_POOL         = os.getenv("LIBVIRT_OS_VOL_POOL", "default")
LIBVIRT_ROOK_VOL_POOL       = os.getenv("LIBVIRT_ROOK_VOL_POOL", "default")

NUM_MASTERS = int(os.getenv("NUM_MASTERS", "1"))
NUM_WORKERS = int(os.getenv("NUM_WORKERS", "2"))

NODE_OS_IMAGE            = os.getenv("NODE_OS_IMAGE",
    "https://download.opensuse.org/distribution/leap/15.0/jeos/openSUSE-Leap-15.0-JeOS.x86_64-15.0.1-OpenStack-Cloud-Current.qcow2")
NODE_VCPUS               = int(os.getenv("NODE_VCPUS", "2"))
NODE_RAM_MB              = int(os.getenv("NODE_RAM_MB", "2048"))
NODE_MIN_OS_DISK_SIZE    = int(os.getenv("NODE_MIN_OS_DISK_SIZE", "30"))
NODE_ROOK_VOLUMES        = int(os.getenv("NODE_ROOK_VOLUMES", "2"))
NODE_ROOK_VOLUME_SIZE_GB = int(os.getenv("NODE_ROOK_VOLUME_SIZE_GB", "10"))

# network will be named <CLUSTER_PREFIX><NET_DOMAIN_NAME>, e.g., 'user-rook-dev.net' if CLUSTER_PREFIX="user-"
NET_DOMAIN_NAME = os.getenv("NET_DOMAIN_NAME", "rook-dev.net")
NET_CIDR = os.getenv("NET_CIDR", "172.60.0.0/22")
