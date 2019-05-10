import cloudconfig
import command
import string
import sys
import virsh

class HardwareConfig:
    def __init__(self, cpus, ram_MB):
        self.cpus = cpus
        self.ram_MB = ram_MB

class OSConfig:
    def __init__(self, parentImage, parentImagePool="default", createdDiskPool="default", minSizeGB=40):
        self.parentImage = parentImage
        self.parentImagePool = parentImagePool
        self.createdDiskPool = createdDiskPool
        self.size = minSizeGB * 1024 * 1024 * 1024

class VolumeConfig:
    def __init__(self, count=4, sizeGB=10, pool="default"):
        self.count = count
        self.sizeGB = sizeGB
        self.pool = pool

class NetworkConfig:
    def __init__(self, networkName):
        self.name = networkName

    def __repr__(self):
        return "'" + self.name + "'"


class LvmDomain:  # a.k.a. - node
    def __init__(self, name, hardwareConfig, osConfig, volumeConfig, networkConfigs):
        self.name = name
        self.hardwareConfig = hardwareConfig
        self.osConfig = osConfig
        self.volumeConfig = volumeConfig
        self.volumes = [
            LvmVolume(name+"-vol-"+str(i), volumeConfig.sizeGB, volumeConfig.pool, "raw")
            for i in range(volumeConfig.count)
        ]
        self.networks = networkConfigs

    def Create(self, uri):
        print("creating domain: "+self.name)
        # create os disk
        virsh.CloneVolume(uri, self.osConfig.parentImagePool, self.osConfig.parentImage,
                               self.osConfig.createdDiskPool, self.name)
        print("created os disk: " + self.name)
        virsh.AddCapacityToVolume(uri, self.osConfig.createdDiskPool, self.name, self.osConfig.size)
        # create cloud init disk
        ciDisk = cloudconfig.GenerateISODisk(uri, self.name, self.osConfig.createdDiskPool,
            "scripts/resources/.ssh/id_rsa", "scripts/resources/.ssh/id_rsa.pub")
        print("created cloud config disk: " + ciDisk)
        # create volumes
        for v in self.volumes:
            v.Create(uri)
        # create domain (with os and cloud-init disks attached at sda and sdb)
        virsh.CreateDomain(uri, self.name, self.hardwareConfig.cpus, self.hardwareConfig.ram_MB,
                                osDiskPool=self.osConfig.createdDiskPool, osDiskName=self.name,
                                ciDiskPool=self.osConfig.createdDiskPool, ciDiskName=ciDisk)
        # update cpu and mem (for when domain already exists)
        virsh.SetDomainCPUandRAM(uri, self.name, self.hardwareConfig.cpus, self.hardwareConfig.ram_MB)
        # attach volumes
        for i in range(len(self.volumes)):
            n = virsh.DeviceNameHintFromID(i, busType="scsi")
            v = self.volumes[i]
            print("attaching volume: " + v.name)
            virsh.AttachVolumeToDomain(uri, v.pool, v.name, self.name, n, busType="scsi")
        # attach to networks
        for n in self.networks:
            print("attaching to network: " + n.name)
            virsh.ConnectDomainToNetwork(uri, self.name, n.name)
        # start domain
        virsh.StartDomain(uri, self.name)

    def Delete(self, uri):
        virsh.DeleteDomain(uri, self.name)
        for v in self.volumes:
            v.Delete()

    def AllVolumes(self):
        vols = [self.name, cloudconfig.CloudInitDiskName(self.name)]
        for v in self.volumes:
            vols = vols + [v.name]
        return vols

    def __repr__(self):
        s = "domain " + self.name + " with ..."
        for v in self.volumes:
            s += "\n  "+str(v)
        for n in self.networks:
            s += "\n  connection to network "+str(n)
        return s


class LvmVolume:
    def __init__(self, name, sizeGb=10, pool="default", volType="qcow2"):
        self.name = name+"."+volType
        self.size = sizeGb * 1024 * 1024 * 1024
        self.pool = pool
        self.type = volType

    def Create(self, uri):
        virsh.CreateVolume(uri, self.pool, self.name, self.size, self.type)

    def Delete(self, uri):
        virsh.DeleteVolume(uri, self.pool, self.name)

    def __repr__(self):
        return(str(self.size/1024/1024/1024) + "Gb " + self.type + " volume '" + self.name +
                "' on pool '" + self.pool + "'")
