
Rook-Ceph Development Environment and Tools
============================================

This development environment and these dev tools can automatically set up a Kubernetes cluster with
a configurable number of nodes which is ready for running Rook in a development context.

The user CLI tooling is based around `gnumake`, which calls Bash/Python scripts for most of the
functionality. `make` is great because it provides builtin tab completion for its targets. Help text
is built into these `make` tools as well, and said help text is intended to be the primary source of
documentation about regular usage.


Prerequisites
--------------

### Known dependencies
 - bash
 - curl
 - libvirt-client
 - libvirt-daemon
 - libvirt-daemon-qemu
 - libvirt-python - https://pypi.org/project/libvirt-python/
 - python3
 - qemu
 - qemu-kvm
 - jq
 - wget

### Go
The environment will install Go for compiling Rook, but the user is still expected to have Go
installed. At minimum, the user must have the `GOPATH` environment variable set, and the Rook
repository should be cloned to `$GOPATH/src/github.com/rook/rook`.


Quickstart
-----------
1. See: `make help`
1. See: `make rook.help`
1. Make any config changes you wish.
1. Run `make quickstart`


More documentation
-------------------
See `/doc` for more documentation.

Environments
-------------
Currently, the only supported environment for building Kubernetes clusters for Rook is `libvirt`.
