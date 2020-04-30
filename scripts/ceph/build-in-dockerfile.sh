#!/usr/bin/env bash
set -Eeuo pipefail

CEPH_DIR="$(readlink --canonicalize-existing "${CEPH_DIR}")"
CCACHE_DIR="$(readlink --canonicalize-existing "${CCACHE_DIR}")"

# Build Ceph in the build container
# Run as current user so files in ceph/ dir aren't created as root:root
# insert our /etc/{passwd,group} files readonly in the container,
#   so sudo doesn't complain about uid not having a name
# insert our local ceph source to build; no need to git pull in the container
# insert our local ccache dir to speed up repeat builds
docker run -t --rm --user="$(id -u $USER):$(id -g $USER)" \
    --volume "/etc/passwd:/etc/passwd:ro" --volume "/etc/group:/etc/group:ro" \
    --volume "${CEPH_DIR}:/src/ceph" \
    --volume "${CCACHE_DIR}:/home/$USER/.ccache" \
    --env CMAKE_FLAGS="${CMAKE_FLAGS}" \
    --env CEPH_BINARIES_TO_BUILD="${CEPH_BINARIES_TO_BUILD}" \
  ceph-build ${BASH_CMD} build-upstream.sh
