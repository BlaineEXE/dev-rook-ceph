
Rook-Ceph Development Environment and Tools
============================================

This development environment and these dev tools can automatically set up a Kubernetes cluster with
a configurable number of nodes which is ready for running Rook in a development context.

The user CLI tooling is based around `gnumake`, which calls Bash/Python scripts for most of the
functionality. `make` is great because it provides builtin tab completion for its targets. Help text
is built into these `make` tools as well, and said help text is intended to be the primary source of
documentation about regular usage.

### Guiding principles
There are some important high-level goals guiding the design of this environment.
 - The CLI tools should be user-friendly
 - The CLI tools should have useful help text and do its best to be its own documentation
 - The tooling should not be arcane; it should be inspectable and extensible by most developers; and
   it should not be overly complex
 - The tooling should prioritize fast development iteration


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

### Octopus
Octopus is a CLI tool for executing commands on and copying files to multiple hosts in parallel
created for this use-case. It is installed automatically by this environment and used for setting up
the cluster. As well, it is installed for the `root` user on all cluster nodes. Octopus gets its
host lists from a file (`_node-list`) written in bash variable syntax (as opposed to something like
a `genders` file). This allows the host lists to be used by both Octopus and by bash scripts. It
also supports hosts defined as IP addresses rather than requiring host names to be specified.

The user may opt to install Octopus for themselves locally, which would allow easy use of the
`octopus` CLI tool from the dev environment root dir, which is set up with a `.octopus`
configuration dir. See https://github.com/BlaineEXE/octopus/releases for more.


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
