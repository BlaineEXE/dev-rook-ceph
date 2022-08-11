#!/usr/bin/env bash
set -u

# Usage:
#  multi-ssh.sh <group> "commands"

# ARGS
group="$1"
script="$2"

ANSIBLE="${ANSIBLE:=ansible}" # might be 'ansible -v' from Makefile, for example
BASH_CMD="${BASH_CMD:=bash}" # might be 'bash -x' from Makefile, for example
CLUSTER_DATA="${CLUSTER_DATA:="$PWD"/.cluster}"

cat <<EOF > /tmp/playbook.yaml
- hosts: ${group}
  gather_facts: no
  tasks:
EOF

# use '--become' to become the root user
# the 'raw' module doesn't require python to be installed
if [[ -f "${script}" ]]; then
  script="$(realpath "${script}")"
  script_name="$(basename "${script}")"
  remote_script_loc="/tmp/${script_name}"
  # ssh -F $(CLUSTER_DATA)/ssh_config -t master "sudo su -"
  cat <<EOF >> /tmp/playbook.yaml
  - local_action: shell scp -F ${CLUSTER_DATA}/ssh_config ${script} {{ inventory_hostname }}:${remote_script_loc}
  - raw: sudo ${BASH_CMD} ${remote_script_loc}
    become: true
    register: result
EOF
else
  cat <<EOF >> /tmp/playbook.yaml
  - raw: ${BASH_CMD} -c '${script}'
    become: true
    register: result
EOF
fi

cat <<EOF >> /tmp/playbook.yaml
  # echo the stdout from all hosts serially to prevent interleaving
  # trim whitespace to prevent randomly added newlines
  - local_action: |
        shell echo "{{- ansible_play_hosts
                      | map('extract', hostvars, 'result')
                      | map(attribute='stdout')
                      | map('trim')
                      | join('\n') -}}" >> /tmp/output
    run_once: yes
EOF

if [[ -n "${DEBUG:-}" ]]; then
  echo '  - debug: msg={{ result }}' >> /tmp/playbook.yaml
  cat /tmp/playbook.yaml
fi

rm -rf /tmp/output
${ANSIBLE_PLAYBOOK} /tmp/playbook.yaml
rc="$?"

echo ""
echo "Collated STDOUT of the command(s) is in /tmp/output"
echo ""

if [[ -n "${DEBUG:-}" ]]; then
  cat /tmp/output
fi

exit "${rc}"

# using this local_action does the echo in parallel and prints interleaved output (NOT GOOD)
# - local_action: shell echo "{{ item }}" >> /tmp/output
#   with_items: "{{ result.stdout }}"
