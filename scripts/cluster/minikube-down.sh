#!/usr/bin/env bash
set -eEuo pipefail

: "${MINIKUBE:-"minikube"}"
: "${PODMAN:-"podman"}"

# # revert back to default docker context
# $PODMAN context use default
# $PODMAN context rm minikube || true

$MINIKUBE delete
