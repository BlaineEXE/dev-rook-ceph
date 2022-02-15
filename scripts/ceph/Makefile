# The theory behind makefile targets is that targets (or target groups) should not share the same
# 3 letters so tab complete is useful for the user. Ideally, the first 2 letters.

export CEPH_DIR ?= ceph/
export CCACHE_DIR ?= .ccache/

# Control the Ceph build with below vars
export CMAKE_FLAGS_ADDL ?=
export CMAKE_FLAGS ?= -DWITH_CCACHE=1 \
                      -DHAS_VTA=0 -DWITH_LEVELDB=0 -DWITH_LTTNG=0 -DWITH_BABELTRACE=0 -DWITH_LZ4=0 \
                      -DWITH_MANPAGE=0 -DENABLE_GIT_VERSION=OFF $(CMAKE_FLAGS_ADDL)
# -DWITH_PYTHON3=1 -DMGR_PYTHON_VERSION=3

# Build only some Ceph binaries to save time
# TODO: Should I also build Mon and MDS like in Rasputin project?
export CEPH_BINARIES_TO_BUILD ?= ceph-mgr

.ceph.repo:
	@ $(BASH_CMD) -c 'if [[ ! -d $(CEPH_DIR)/.git/ ]] ; then \
	    echo "  ERROR! Ceph has not been cloned to workspace; cannot continue!"; exit 1; fi'

.ceph.buildcontainer:
	@ echo "Ensuring ceph-build container. Takes a LONG time at first run, just a second after."
	@ $(PODMAN) build -t ceph-build scripts/ceph/build-container

$(CCACHE_DIR):
	@ mkdir -p "$(CCACHE_DIR)"


##
## CEPH BUILD TARGETS
##   ceph.build: (TODO: DESCRIPTION, TODO: fix broken build)
ceph.build: .ceph.repo .ceph.buildcontainer $(CCACHE_DIR)
	@ $(BASH_CMD) scripts/ceph/build-in-dockerfile.sh

export CEPH_BASE_IMAGE ?= ceph/daemon-base
##   ceph.build.image   Overlay locally-built Ceph files on top of a Ceph base image, and push the
##                          image as ${IMG}ceph/ceph:local${NON}.
##                          Default base image: ${ENV}CEPH_BASE_IMAGE=${CEPH_BASE_IMAGE}${NON}.
PYTHON_COPY_DIR ?= scripts/ceph/ceph-container/.python-files
ceph.build.image: .ceph.repo
	@ echo '  BUILDING CEPH IMAGE AS ceph/ceph:local'
	@ rm -rf $(PYTHON_COPY_DIR) && mkdir -p $(PYTHON_COPY_DIR)
	@ cp -a ceph/src/python-common $(PYTHON_COPY_DIR)/python-common
	@ cp -a ceph/src/ceph-volume   $(PYTHON_COPY_DIR)/ceph-volume
	@ $(PODMAN) build -t ceph/ceph:local scripts/ceph/ceph-container
	@ $(MAKE) cluster.push-image IMG="ceph/ceph:local" TAG="ceph/ceph:local"
	@ bash scripts/resources/success-message.sh "CEPH IMAGE BUILT AND PUSHED AS ceph/ceph:local"


#
# Help
#
.PHONY: ceph.help
# Use sed on this makefile to render all lines beginning with '##'
ceph.help: scripts/ceph/Makefile.help
