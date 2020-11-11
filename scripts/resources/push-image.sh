#!/usr/bin/env bash

# ARGS
local_image="$1"
remote_image="$2"

source scripts/shared.sh

echo "Pushing local image ${local_image} to nodes as ${remote_image}..."

# Tag our locally built image with the remote image name
echo "  Tagging local image ${local_image} as ${remote_image}..."
docker tag "${local_image}" "${remote_image}"

local_image_dir=".images"
node_image_dir="/root/.images"
mkdir -p "${local_image_dir}"

tarball_name="${remote_image}"      # name tarball based on remote image name
tarball_name="${tarball_name//:/-}" # replace : with -
tarball_name="${tarball_name////-}" # replace / with -
tarball_name="${tarball_name//./-}" # replace . with .
tarball_name="${tarball_name}.tar"  # add .tar suffix

# Save the image to a tar file which can be loaded into docker on nodes
# Compressing the file with gzip can take 4 times as long, so it's not worth it
tarfile="${local_image_dir}"/"${tarball_name}"
echo "  Saving image ${remote_image} to tar file ${tarfile}..."
docker save "${remote_image}" > "${tarfile}"

echo "  Copying tar file to cluster nodes..."
suppress_output_unless_error "${MULTI_COPY} all '${tarfile}' '${node_image_dir}/'"

echo "  Loading tar file on all cluster nodes..."
suppress_output_unless_error "${MULTI_SSH} all 'docker load --input \"${node_image_dir}/${tarball_name}\"'"

echo "Done pushing image ${local_image} to cluster as image ${remote_image}!"
