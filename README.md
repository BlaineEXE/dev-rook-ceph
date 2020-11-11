
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
 - The tooling should be idempotent when possible


Prerequisites
--------------

### Known dependencies
 - bash
 - curl
 - docker
 - vagrant
 - vagrant plugin: vagrant-reload
 - virtualbox
 - kubectl
 - jq
 - wget

### Go
The environment will install Go for compiling Rook.


Quickstart
-----------
1. See: `make help`
1. See: `make rook.help`
1. Make any config changes you wish.
1. Run `make cluster.build`


Environments
-------------
Currently, the only supported environment for building Kubernetes clusters for Rook is created by
[k8s-vagrant-multi-node](https://github.com/galexrt/k8s-vagrant-multi-node).
