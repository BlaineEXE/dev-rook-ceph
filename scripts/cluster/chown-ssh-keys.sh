#!/usr/bin/env bash
set -Eeuo pipefail

# git doesn't seem to keep 600 permissions very well, and this is absolutely required for SSH to
# work to hosts.
chown 600 scripts/resources/.ssh/id_rsa
chown 644 scripts/resources/.ssh/id_rsa.pub
