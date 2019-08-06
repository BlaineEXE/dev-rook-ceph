import command
import os
import os.path as path
import virsh
import yaml

def CloudInitDiskName(hostname):
    return hostname + "-cloud-init.iso"

def GenerateISODisk(uri, hostname, diskPool, sshPrivateKeyfile, sshPublicKeyfile):
    metadata = generateMetadata(hostname)
    userdata = generateUserdata(hostname, sshPrivateKeyfile, sshPublicKeyfile)
    netdata = generateNetworkData()

    tmpDir = path.join("/tmp", hostname)
    os.makedirs(tmpDir, exist_ok=True)

    mPath = path.join(tmpDir, "meta-data")
    f = open(mPath, "w")
    f.write("#cloud-config")
    f.write(yaml.dump(metadata, default_flow_style=False))
    f.close()

    # these configs don't seem to work in the `user-data` file, so use `network-config`
    nPath = path.join(tmpDir, "network-config")
    f = open(nPath, "w")
    f.write("#cloud-config")
    f.write(yaml.dump(netdata, default_flow_style=False))
    f.close()

    uPath = path.join(tmpDir, "user-data")
    f = open(uPath, "w")
    f.write("#cloud-config\n\n")
    f.write(yaml.dump(userdata, default_flow_style=False))
    f.close()

    ciFile = path.join(tmpDir, "cloud-init.iso")
    command.Run(["mkisofs",
        "-output", ciFile, "-volid", "cidata", "-joliet", "-rock", mPath, uPath, nPath,
    ])

    ciVol = CloudInitDiskName(hostname)

    # Delete and recreate in case cloud init has been modified
    virsh.DeleteVolume(uri, diskPool, ciVol)
    virsh.UploadVolume(uri, diskPool, ciVol, 5242800, "raw", ciFile)

    return(ciVol)


def generateMetadata(hostname):
    metadata = {}
    metadata["instance-id"] = hostname
    metadata["hostname"] = hostname
    return metadata

# cloud-init has a habit of clobbering /etc/resolv.conf
def generateNetworkData():
    cfg = {}
    net = {}
    net["version"] = "1"
    net["config"] = "disabled"
    cfg["network"] = net
    return cfg

def generateUserdata(hostname, sshPrivateKeyfile, sshPublicKeyfile):
    # start w/ template
    template = open("scripts/libvirt/cloud-init-template.cls", "r")
    userdata = yaml.safe_load(template)
    template.close()

    userdata["hostname"] = hostname

    # read private & public key files
    f = open(sshPrivateKeyfile)
    privateKey = f.read().strip()
    f.close()
    f = open(sshPublicKeyfile)
    publicKey = f.read().strip()
    f.close()

    # add "ssh_keys" section w/ key files
    sshKeys = userdata.get("ssh_keys", {})
    sshKeys["rsa_private"] = privateKey
    sshKeys["rsa_public"] = publicKey
    userdata["ssh_keys"] = sshKeys

    # add public key to ssh authorized keys for root user
    users = userdata.get("users", [])
    foundRoot = False
    for user in users:
        if user.get("name", "") == "root":
            foundRoot = True
    if not foundRoot:
        users += [{"name": "root"}]
    for user in users:
        if user.get("name", "") == "root":
            user["ssh_authorized_keys"] = user.get("ssh_authorized_keys", []) + [publicKey]

    return userdata
