import virsh
import network

from variables import *
from setup import nodes, k8sNet, resourceBelongsToThisCluster


if len(nodes) > 0:
    k8sNet.Create(LIBVIRT_URI)
for n in nodes:
    n.Create(LIBVIRT_URI)

# delete nodes that are no longer desired
doms = virsh.ListDomains(LIBVIRT_URI)
# print("nodes: " + str(doms))
for d in doms:
    if not resourceBelongsToThisCluster(d):
        continue # don't consider resources that aren't part of this cluster
    desiredNodes = [n.name for n in nodes]
    # print("desired nodes: " + str(desiredNodes))
    if not d in desiredNodes:
        virsh.DeleteDomain(LIBVIRT_URI, d)

# delete volume resources that are no longer desired
for pool in [LIBVIRT_OS_VOL_POOL, LIBVIRT_ROOK_VOL_POOL]:
    vols = virsh.ListVolumes(LIBVIRT_URI, pool)
    # print("vols: " + str(vols))
    for v in vols:
        if not resourceBelongsToThisCluster(v):
            continue # don't consider resources that aren't part of this cluster
        desiredVolumes = []
        for n in nodes:
            desiredVolumes = desiredVolumes + n.AllVolumes()
        # print("desired vols: " + str(desiredVolumes))
        if not v in desiredVolumes:
            virsh.DeleteVolume(LIBVIRT_URI, pool, v)

if len(nodes) == 0:
    k8sNet.Delete(LIBVIRT_URI)

exit(0)
