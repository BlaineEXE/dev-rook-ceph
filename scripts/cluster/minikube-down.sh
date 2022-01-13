#!/usr/bin/env bash
set -eEuo pipefail

: "${MINIKUBE:-"minikube"}"

# revert back to default docker context
docker context use default
docker context rm minikube

$MINIKUBE delete
