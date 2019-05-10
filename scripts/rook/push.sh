#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

# Tag our built image as "rook/ceph:master"
# This is because Rook integration tests assume the image under test is "rook/ceph:master"
docker tag "rook-build/ceph-${GOARCH:-amd64}" rook/ceph:master

local_image_dir="${PWD}/.images/"
node_image_dir="/root/.images/"
mkdir -p "${local_image_dir}"
tarfile="rook-ceph-master.tar"

# Save the image to a tar file which can be loaded into docker on nodes
# Compressing the file with gzip can take 4 times as long, so it's not worth it
echo "Saving Rook Ceph image to a tar file ..."
docker save rook/ceph:master > "${local_image_dir}"/"${tarfile}"

echo "Copying Rook Ceph image to cluster nodes ..."
# buffer size 256 fails sometimes w/ EOF. 128 seems safe. 64 isn't noticeably slower on ECP
# For local clusters, this should be fastest
${OCTOPUS} --host-groups all copy "${local_image_dir}"/"${tarfile}" "${node_image_dir}" --buffer-size 128

echo "Loading Rook Ceph image tar files on cluster nodes ..."
${OCTOPUS} --host-groups all run "docker load --input ${node_image_dir}/${tarfile}"

echo "Done!"
