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

# because ssh runs as 'vagrant' user by default, use '--become' to become the root user
if [[ -f "${script}" ]]; then
  # if xtrace is set, insert 'set -x' on the second line of the script before copying it
  if [[ "${BASH_CMD}" == *"-x"* ]]; then
    sed '1a\
set -x
' "${script}" > /tmp/script
    script="/tmp/script"
    # cat /tmp/script
  fi
  ${ANSIBLE} "${group}" --become -m script -a "${script}"
else
  ${ANSIBLE} "${group}" --become -m shell -a "${BASH_CMD} -c '$script'"
fi
