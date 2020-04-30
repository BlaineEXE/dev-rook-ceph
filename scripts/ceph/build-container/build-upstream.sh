#!/usr/bin/env bash
set -Eeuo pipefail

( cd ceph/
  # Run install deps just in case any dependencies are missed in the Dockerfile after Ceph updates
  bash install-deps.sh
  if [ ! -d build ]; then
    # cmake options documented by 'cmake -LH'
    echo "Running cmake with flags: ${CMAKE_FLAGS}"
    bash do_cmake.sh ${CMAKE_FLAGS}
  fi
  ( cd build/
    echo "Building Ceph daemon binaries: ${CEPH_BINARIES_TO_BUILD}"
    echo "Building in parallel; output is buffered and output after each section is complete"
    jobs="$(nproc --all)" || jobs=8  # default to 8 jobs if nproc fails
    # make --jobs="${jobs}" --output-sync ${CEPH_BINARIES_TO_BUILD}
  )
)
