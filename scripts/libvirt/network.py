import libvirt
import ipaddress

class LvmNetwork:
    def __init__(self, networkName, domainName, networkWithCIDR):
        self.networkName = networkName
        self.domainName = domainName
        self.network = networkWithCIDR

    def Create(self, uri):
        CreateNetwork(uri, self.networkName, self.domainName, self.network)
        StartNetwork(uri, self.networkName) # if net has been turned off by user or system reboot

    def Delete(self, uri):
        DeleteNetwork(uri, self.networkName)

    def __repr__(self):
        return "network '" + self.network + "' named '" + self.domainName + "'"


def NetworkExists(uri, networkName):
    conn = libvirt.open(uri)
    try:
        _ = conn.networkLookupByName(networkName)
        conn.close()
        return(True)
    except:
        conn.close()
        return(False)

def CreateNetwork(uri, networkName, domainName, networkWithCIDR):
    if NetworkExists(uri, networkName):
        print("network already exists: " + networkName)
        return
    n = ipaddress.ip_network(networkWithCIDR)
    netmask = str(n.netmask)
    dhcpEnd = str(n.broadcast_address - 1)
    hosts = list(n.hosts())
    firstHost = str(hosts[0])
    middleHost = str(hosts[int(len(hosts)/2)])
    conn = libvirt.open(uri)
    x = """<network connections='1'>
  <name>{networkName}</name>
  <forward mode='nat'>
    <nat>
      <port start='1024' end='65535'/>
    </nat>
  </forward>
  <domain name='{domainName}' localOnly='no'/>
  <ip address='{host_ip}' netmask='{mask}'>
    <dhcp>
      <range start='{dhcp_start}' end='{dhcp_end}'/>
    </dhcp>
  </ip>
  <dns></dns>
</network>""".format(networkName= networkName, domainName=domainName,
                     host_ip=firstHost, mask=netmask,
                     dhcp_start=middleHost, dhcp_end=dhcpEnd)
    conn.networkDefineXML(x)
    conn.close()

def StartNetwork(uri, networkName):
    conn = libvirt.open(uri)
    n = conn.networkLookupByName(networkName)
    if n.isActive():
        conn.close()
        return
    n.create()
    conn.close()

def DeleteNetwork(uri, networkName):
    if not NetworkExists(uri, networkName):
        print("network already deleted: " + networkName)
        return
    conn = libvirt.open(uri)
    n = conn.networkLookupByName(networkName)
    if n.isActive():
      n.destroy()
    n.undefine()
    conn.close()
    print("deleted network: " + networkName)

def ListNetworkDHCPLeases(uri, networkName):
  if not NetworkExists(uri, networkName):
      print("network does not exist to get DHCP leases: " + networkName)
      return {}
  conn = libvirt.open(uri)
  n = conn.networkLookupByName(networkName)
  rawLeases = n.DHCPLeases()
  conn.close()
  leases = {}
  for lease in rawLeases:
    leases[lease["hostname"]] = lease["ipaddr"]
  return leases
