#cloud-config

locale: en_US.UTF-8
timezone: UTC

ntp:
  servers:
    - 0.pool.ntp.org
    - 1.pool.ntp.org
    - 2.pool.ntp.org
    - 3.pool.ntp.org

# set root password
# Do not use a simple pass on public networks
ssh_pwauth: True
chpasswd:
  list: |-
    root:linux
  expire: False

disable_root: false
system_info:
  default_user:
    name: root

users:
  - name: root
    # ssh_authorized_keys:
    #   - auto-populated from scripts/resources/.ssh/id_rsa.pub

# ssh_keys:
#   rsa_private: auto-populated from scripts/resources/.ssh/id_rsa
#   rsa_public: auto-populated from scripts/resources/.ssh/id_rsa.pub

runcmd:
  - cp /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa
  - cp /etc/ssh/ssh_host_rsa_key.pub /root/ssh/id_rsa.pub

final_message: "system up after $UPTIME seconds"
