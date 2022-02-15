#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

make_target="${*}"

echo "Calling Rook to make only Ceph using GOROOT ${GOROOT}"

make --directory="${ROOK_REPO_DIR}" -j ${make_target} \
    GOOS='linux' GOARCH='amd64' BUILD_REGISTRY='rook-build' IMAGES='ceph' DOCKERCMD='podman'
