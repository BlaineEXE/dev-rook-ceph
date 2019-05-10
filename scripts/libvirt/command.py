import subprocess

def Run(command):
    res = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if res.returncode != 0:
        raise Exception("run command failed: " + " ".join(command) + "\nresult: " + str(res))
    return(res.stdout)

# return true if command succeeds, false otherwise
def Check(command):
    try:
        Run(command)
        return True
    except:
        return False
