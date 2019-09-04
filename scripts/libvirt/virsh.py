import command
import libvirt
import os.path
import requests
import xml.etree.ElementTree as xml

#
# domains (a.k.a. nodes)
#

def ListDomains(uri):
    conn = libvirt.open(uri)
    doms = conn.listAllDomains()
    names = []
    for d in doms:
        names = names + [d.name()]
    conn.close()
    return names

def DomainExists(uri, name):
    conn = libvirt.open(uri)
    try:
        _ = conn.lookupByName(name)
        conn.close()
        return True
    except:
        conn.close()
        return False

# Creates os disk on "sda" and cloud-init disk on "sdb" (cdrom)
def CreateDomain(uri, name, cpus, ram_MB,
                      osDiskPool, osDiskName,
                      ciDiskPool, ciDiskName):
    if DomainExists(uri, name):
        print("domain exists; not creating domain: " + name)
        return
    print("domain does not exist: " + name)
    x = generateDomainXML(name, cpus, ram_MB)
    conn = libvirt.open(uri)
    d = conn.defineXML(x)
    # os disk
    p = conn.storagePoolLookupByName(osDiskPool)
    v = p.storageVolLookupByName(osDiskName)
    x = """<disk type='file'>
  <source file='{}'/>
  <target dev='sda' bus='sata'/>
</disk>""".format(volPath(v))
    d.attachDeviceFlags(x, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG)
    # cloud-init disk
    p = conn.storagePoolLookupByName(ciDiskPool)
    v = p.storageVolLookupByName(ciDiskName)
    x = """<disk type='file' device='cdrom'>
  <source file='{}'/>
  <readonly/>
  <target dev='sdb' bus='sata'/>
</disk>""".format(volPath(v))
    d.attachDeviceFlags(x, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG)
    #
    conn.close()

def StartDomain(uri, domainName):
    conn = libvirt.open(uri)
    d = conn.lookupByName(domainName)
    if d.isActive():
      print("domain is already running: " + domainName)
      return
    d.create()
    conn.close()

def StopDomain(uri, domainName):
    print("stopping domain: "  + domainName)
    conn = libvirt.open(uri)
    d = conn.lookupByName(domainName)
    d.destroyFlags(flags=libvirt.VIR_DOMAIN_DESTROY_GRACEFUL)
    conn.close()

def DeleteDomain(uri, domainName):
    if not DomainExists(uri, domainName):
        print("domain is already deleted: " + domainName)
        return
    print("deleting domain: " + domainName)
    conn = libvirt.open(uri)
    d = conn.lookupByName(domainName)
    if d.isActive():
        d.destroy() # force stop
    d.undefine()
    conn.close()

def SetDomainCPUandRAM(uri, domainName, cpus, ram_MB):
    conn = libvirt.open(uri)
    d = conn.lookupByName(domainName)
    d.setVcpusFlags(cpus, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG+libvirt.VIR_DOMAIN_VCPU_MAXIMUM)
    d.setVcpusFlags(cpus, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG)
    ram = ram_MB * 1024
    # d.setMaxMemory()
    d.setMemoryFlags(ram, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG+libvirt.VIR_DOMAIN_MEM_MAXIMUM)
    d.setMemoryFlags(ram, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG)
    if d.isActive():
      try:
        d.setVcpusFlags(cpus, flags=libvirt.VIR_DOMAIN_AFFECT_LIVE)
      except:
        print("could not hot modify CPU count on domain; power cycle VM to update: " + domainName)
      try:
        d.setMemoryFlags(ram, flags=libvirt.VIR_DOMAIN_AFFECT_LIVE)
      except:
        print("could not hot modify RAM on domain; power cycle VM to update: " + domainName)
    conn.close()

def DeviceNameHintFromID(id_num, busType="scsi"):
    startOrd = ord("a")
    if busType == "scsi" or busType == "sata":
      devPrefix = "sd"
      startOrd = ord("c") # for sata/scsi 'a' and 'b' are taken by os and cloud-init disks
    elif busType == "ide":
      devPrefix = "hd"
    else:
      devPrefix = "vd"
    return( devPrefix + chr(id_num + startOrd) )

def VolIsAttachedToDomain(uri, volPool, volName, domainName):
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(volPool)
    v = p.storageVolLookupByName(volName)
    vPath = volPath(v)
    d = conn.lookupByName(domainName)
    domXML = d.XMLDesc()
    conn.close()
    x = xml.fromstring(domXML)
    devs = x.find("devices")
    disks = devs.findall("disk")
    for d in disks:
      s = d.find("source")
      if s.attrib["file"] == vPath:
        return(True)
    return(False)

# example deviceNameHint = "sdc" | "vdd" | "hda"  # is only a hint to device ordering
# busType = "sata" | "scsi" (default) | "virtio" | "ide"
def AttachVolumeToDomain(uri, volPool, volName, domainName, deviceNameHint, diskFmt="qcow2", busType="scsi"):
    if VolIsAttachedToDomain(uri, volPool, volName, domainName):
      print("volume '" + volName + "' is already attached to domain '" + domainName + "'")
      return
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(volPool)
    v = p.storageVolLookupByName(volName)
    x = """<disk type='file'>
  <source file='{file}'/>
  <driver name='qemu' type='{fmt}'/>
  <target dev='{dev}' bus='{bus}'/>
</disk>""".format(file=volPath(v), dev=deviceNameHint, fmt=diskFmt, bus=busType)
    d = conn.lookupByName(domainName)
    d.attachDeviceFlags(x, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG)
    if d.isActive():
        try:
          d.attachDeviceFlags(x, flags=libvirt.VIR_DOMAIN_AFFECT_LIVE)
        except:
          print("could not hot-attach volume '" + volName + "' to domain '" + domainName + "'; power cycle VM to add disk")
    conn.close()

def DomainIsConnectedToNetwork(uri, domainName, networkName):
    conn = libvirt.open(uri)
    d = conn.lookupByName(domainName)
    domXML = d.XMLDesc()
    conn.close()
    x = xml.fromstring(domXML)
    devs = x.find("devices")
    interfaces = devs.findall("interface")
    for i in interfaces:
        # print("interface: " + str(i))
        if not i.attrib["type"] == "network":
            continue
        s = i.find("source")
        if s.attrib["network"] == networkName:
            return(True)
    return(False)

def ConnectDomainToNetwork(uri, domainName, networkName):
    if DomainIsConnectedToNetwork(uri, domainName, networkName):
        print("domain '" + domainName + "' is already connected to network '" + networkName + "'")
        return
    conn = libvirt.open(uri)
    d = conn.lookupByName(domainName)
    x = """<interface type='network'>
    <source network='{name}'/>
</interface>""".format(name=networkName)
    d.attachDeviceFlags(x, flags=libvirt.VIR_DOMAIN_AFFECT_CONFIG)
    if d.isActive():
        try:
          d.attachDeviceFlags(x, flags=libvirt.VIR_DOMAIN_AFFECT_LIVE)
        except:
          print("could not hot-attach domain '" + domainName + "' to network '" + networkName + "'; power cycle VM to connect network")
    conn.close()

def generateDomainXML(name, cpus, ram_MB):
    x = """<domain type='kvm'>
  <name>{name}</name>
  <vcpu placement='static'>{cpus}</vcpu>
  <memory unit='MiB'>{ram}</memory>
  <os>
    <type>hvm</type>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <console type='pty'>
    <target type='virtio' port='0'/>
  </console>
  <devices>
    <graphics type='spice' autoport='yes'>
    </graphics>
    <video>
    </video>
  </devices>
</domain>""".format(name=name, cpus=cpus, ram=ram_MB)
    return(x)


#
# volumes
#

def ListVolumes(uri, pool):
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(pool)
    p.refresh()
    vols = p.listVolumes()
    conn.close()
    return vols

def VolumeExists(uri, pool, name):
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(pool)
    p.refresh()
    try:
        _ = p.storageVolLookupByName(name)
        conn.close()
        # print("volume exists: " + name)
        return True
    except:
        conn.close()
        # print("volume does not exist: " + name)
        return False

def CreateVolume(uri, pool, name, capacity, fmt):
    if VolumeExists(uri, pool, name):
        print("volume already exists: " + name)
        return # already exists, don't recreate
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(pool)
    x = generateVolumeXML(p, name, capacity, fmt)
    # print(x)
    p.createXML(x)
    p.refresh()
    conn.close()
    print("created volume: " + name)

def DeleteVolume(uri, pool, name):
    if not VolumeExists(uri, pool, name):
        print("volume is already deleted: " + name)
        return  # does not exist
    print("deleting volume: " + name)
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(pool)
    v = p.storageVolLookupByName(name)
    # v.wipe() # delete underlying disk media (takes a long time?)
    v.delete() # delete from pool
    p.refresh()
    conn.close()

def UploadVolume(uri, pool, name, capacity, fmt, sourceFile):
    if not VolumeExists(uri, pool, name):
        CreateVolume(uri, pool, name, capacity, fmt)
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(pool)
    v = p.storageVolLookupByName(name)
    s = conn.newStream()
    v.upload(s, 0, capacity)
    f = open(sourceFile, "rb")
    s.send(f.read()) # libvirt methods are not user friendly
    s.finish()
    f.close()
    conn.close()
    print("uploaded file to vol: " + sourceFile + " -> " + name)

def CloneVolume(uri, sourcePool, sourceName, destPool, destName):
    if VolumeExists(uri, destPool, destName):
        print("volume '" + destName + "' already exists; not cloning from '" + sourceName + "'")
        return
    conn = libvirt.open(uri)
    sp = conn.storagePoolLookupByName(sourcePool)
    sv = sp.storageVolLookupByName(sourceName)
    dp = conn.storagePoolLookupByName(destPool)
    cx = generateCloneVolumeXML(dp, destName)
    cv = dp.createXMLFrom(cx, sv)
    if cv == None:
      raise Exception("failed to clone volume '" + sourceName + "' to '" + destName + "'")
    print("cloned volume '" + sourceName + "' to '" + destName + "'")
    conn.close()

def AddCapacityToVolume(uri, pool, name, capacity):
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(pool)
    v = p.storageVolLookupByName(name)
    v.resize(capacity, flags=libvirt.VIR_STORAGE_VOL_RESIZE_DELTA)
    conn.close()

def DownloadImageToVolume(uri, imageURL, toPool):
    print("image url: " + imageURL)
    imageName = imageURL.split("/")[-1]
    if VolumeExists(uri, toPool, imageName):
        print("image is already downloaded: " + imageName)
        return(imageName)
    conn = libvirt.open(uri)
    p = conn.storagePoolLookupByName(toPool)
    dest = os.path.join(poolSourceDir(p), imageName)
    conn.close()
    print("    downloading image: " + imageName)
    osImage = requests.get(imageURL, allow_redirects=True)
    open(dest, "wb").write(osImage.content)
    print("    finished downloading image: " + imageName)
    return(imageName)

def generateVolumeXML(virStoragePool, name, capacity, fmt):
    stgDir = poolSourceDir(virStoragePool)
    x = """<volume>
  <name>{}</name>
  <capacity>{}</capacity>
  <target>
    <path>{}</path>
    <format type='{}'/>
  </target>
</volume>""".format(name, capacity, os.path.join(stgDir, name), fmt)
    return(x)

def generateCloneVolumeXML(virStoragePool, name):
    stgDir = poolSourceDir(virStoragePool)
    x = """<volume>
  <name>{}</name>
  <target>
    <path>{}</path>
  </target>
</volume>""".format(name, os.path.join(stgDir, name))
    return(x)

# dir where pool's vol files live
def poolSourceDir(virStoragePool):
    poolXML = virStoragePool.XMLDesc()
    # print(poolXML)
    x = xml.fromstring(poolXML)
    t = x.find("target")
    p = t.find("path")
    return(p.text)

# full path to vol file
def volPath(virVolume):
    volXML = virVolume.XMLDesc()
    x = xml.fromstring(volXML)
    t = x.find("target")
    p = t.find("path")
    return(p.text)
