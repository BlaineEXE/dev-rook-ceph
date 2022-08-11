#!/usr/bin/env bash
set -eEuo pipefail

: "${PODMAN:="podman"}"

$PODMAN machine ssh sudo tee /etc/containers/registries.conf.d/555-insecure-local.conf <<EOF
unqualified-search-registries=["localhost:5000"]

[[registry]]
location = "localhost:5000"
insecure = true
EOF
