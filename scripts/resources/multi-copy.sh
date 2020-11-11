#!/usr/bin/env bash
set -u

# Usage:  multi-copy.sh <group> <src file or dir> <dest dir>

# ARGS
group="$1"
src="$2" # single file or dir
dest="$3" # single file or dir ending in '/'

ANSIBLE="${ANSIBLE:-ansible}" # might be 'ansible -v' from Makefile, for example

${ANSIBLE} "${group}" --become -m copy -a "src='${src}' dest='${dest}'"
