#!/usr/bin/env bash
set -u

# Usage:
#  Option 1:  multi-ssh.sh <group> my-script.sh
#  Option 2:  multi-ssh.sh <group> "commands"

# ARGS
group="$1"
script="$2"

ANSIBLE="${ANSIBLE:-ansible}" # might be 'ansible -v' from Makefile, for example
BASH_CMD="${BASH_CMD:-bash}" # might be 'bash -x' from Makefile, for example

cat <<EOF > /tmp/playbook.yaml
- hosts: ${group}
  gather_facts: no
  tasks:
EOF

# because ssh runs as 'vagrant' user by default, use '--become' to become the root user
if [[ -f "${script}" ]]; then
  script="${PWD}/${script}"
  # ${ANSIBLE} "${group}" --become -m script -a "${script}"
  cat <<EOF >> /tmp/playbook.yaml
  - copy:
      src: "${script}"
      dest: /tmp/script.sh
    become: true
  - shell: ${BASH_CMD} /tmp/script.sh
    become: true
    register: result
EOF
else
  # ${ANSIBLE} "${group}" --become -m shell -a "${BASH_CMD} -c '$script'"
  cat <<EOF >> /tmp/playbook.yaml
  - shell: ${BASH_CMD} -c '${script}'
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

echo ""
echo "Collated STDOUT of the command(s) is in /tmp/output"
echo ""

if [[ -n "${DEBUG:-}" ]]; then
  cat /tmp/output
fi

# using this local_action does the echo in parallel and prints interleaved output (NOT GOOD)
# - local_action: shell echo "{{ item }}" >> /tmp/output
#   with_items: "{{ result.stdout }}"
