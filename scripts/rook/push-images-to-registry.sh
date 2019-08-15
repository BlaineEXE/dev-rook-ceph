#!/usr/bin/env bash
set -Eeuo pipefail

rook_images="$(docker images --format '{{.Repository}}' 'rook-build/ceph*')"

image_tag_pairs=()
for image in $rook_images; do
  image_tag_pairs+=("${image}" "${image#rook-build/}:latest")
done

${BASH_CMD} scripts/dev-env/registry-push-images.sh "${image_tag_pairs[@]}"
