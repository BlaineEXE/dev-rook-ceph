#!/usr/bin/env bash
set -Eeuo pipefail

# ARGS
local_image="$1"
remote_image="$2"

source scripts/shared.sh

# Tag our locally built image with the remote image name
echo "Tagging local image ${local_image} as ${remote_image} ..."
docker tag "${local_image}" "${remote_image}"

local_image_dir="${PWD}/.images/"
node_image_dir="/root/.images/"
mkdir -p "${local_image_dir}"

tarball_name="${remote_image}"      # name tarball based on remote image name
tarball_name="${tarball_name//:/-}" # replace : with -
tarball_name="${tarball_name////-}" # replace / with -
tarball_name="${tarball_name//./-}" # replace . with .
tarball_name="${tarball_name}.tar"  # add .tar suffix

# Save the image to a tar file which can be loaded into docker on nodes
# Compressing the file with gzip can take 4 times as long, so it's not worth it
tarfile="${local_image_dir}"/"${tarball_name}"
echo "Saving image ${remote_image} to tar file ${tarfile} ..."
docker save rook/ceph:master > "${tarfile}"

echo "Copying image tar file ${tarfile} to cluster nodes ..."
# buffer size 256 fails sometimes w/ EOF. 128 seems safe. 64 isn't noticeably slower on ECP
# For local clusters, this should be fastest
${OCTOPUS} --host-groups all copy "${tarfile}" "${node_image_dir}" --buffer-size 128

echo "Loading tar file ${tarfile} on all cluster nodes ..."
${OCTOPUS} --host-groups all run "docker load --input ${node_image_dir}/${tarball_name}"

echo "Done pushing image ${local_image} to cluster as image ${remote_image}!"
