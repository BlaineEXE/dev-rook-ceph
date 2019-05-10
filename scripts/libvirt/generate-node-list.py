import network
import re
import time

from variables import *
from setup import k8sNet, nodes

TIMEOUT = 5 * 60
sTime = time.time()
leases = network.ListNetworkDHCPLeases(LIBVIRT_URI, k8sNet.networkName)
print("Waiting {} minutes for cluster nodes to have DHCP leases ...".format(int(TIMEOUT/60)), end="", flush=True)
while len(leases) < NUM_MASTERS + NUM_WORKERS:
    if time.time() - sTime > TIMEOUT:
        print(" timed out!")
        exit(1)
    time.sleep(5)
    print(".", end="", flush=True)
    leases = network.ListNetworkDHCPLeases(LIBVIRT_URI, k8sNet.networkName)
print(" done.")

print("Generating _node-list ... ", end="", flush=True)

masterIPs = []
workerIPs = []
fileTxt = """#!/usr/bin/env bash

#
# Required _node-list variables
#
"""
convenienceTxt = ""
for n in nodes:
    ip = leases[n.name]
    # make an entry for each hostname
    saniName = re.sub("[\W]+", "_", n.name)
    convenienceTxt += "{}=\"{}\"\n".format(saniName, ip)
    if "master" in n.name:
        masterIPs += [ip]
    elif "worker" in n.name:
        workerIPs += [ip]


fileTxt += "\nmasters=\""
for ip in masterIPs:
    fileTxt += ip + "\n"
fileTxt = fileTxt.rstrip("\n")
fileTxt += "\""
fileTxt += "\n"

fileTxt += "\nworkers=\""
for ip in workerIPs:
    fileTxt += ip + "\n"
fileTxt = fileTxt.rstrip("\n")
fileTxt += "\""
fileTxt += "\n"

fileTxt += """\nall=\"${masters} ${workers}\"

first_master=\"${masters%%[$'\\n' ]*}\"
noninitial_masters=\"${masters/$first_master/}\"
"""

fileTxt += """

#
# Non-required, convenience _node-list variables
#
""" + convenienceTxt

fileTxt += "\n"

print("done.")

# print(fileTxt)
f = open("_node-list", "w")
f.write(fileTxt)
f.close()

exit(0)
