#!/usr/bin/env bash
set -Eeuo pipefail

source scripts/shared.sh

echo -n "Installing dependencies. This could take a while ... "
# install deps (not all are deps; some just make life easier debugging)
suppress_output_unless_error "${OCTOPUS} --host-groups all run \
  'zypper --non-interactive --gpg-auto-import-keys \
    install -y \
      bash-completion \
      ca-certificates \
      conntrack-tools \
      curl \
      docker \
      ebtables \
      ethtool \
      lvm2 \
      lsof \
      ntp \
      socat \
      tree \
      vim \
      wget \
      xfsprogs \
  '"
echo "done."

echo -n "Updating kernel. This can also take a little while ... "
# kernel-default has ipvs kernel modules
suppress_output_unless_error "${OCTOPUS} --host-groups all run \
  'zypper --non-interactive --gpg-auto-import-keys \
    install --allow-downgrade --force-resolution -y \
      kernel-default \
  '"
echo "done."

echo -n "Removing anti-dependencies ... "
suppress_output_unless_error "${OCTOPUS} --host-groups all run \
  'zypper --non-interactive --gpg-auto-import-keys \
    remove -y \
      firewalld \
  ' || true"
  # '|| true' b/c this fails if anti-deps already removed and is unlikely to fail otherwise
echo "done."

echo -n "Enabling docker ..."
# enable and start docker service
suppress_output_unless_error "${OCTOPUS} --host-groups all run 'systemctl enable --now docker'"
echo "done."

echo -n "Rebooting nodes ..."
${OCTOPUS} --host-groups all run reboot &>/dev/null || true # will fail b/c conn will be lost
${BASH} scripts/cluster/wait-for-up.sh
