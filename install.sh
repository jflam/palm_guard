#!/bin/bash
# Install (or update) palm-guard as a root systemd service.
# Uninstall: ./install.sh --uninstall
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" == "--uninstall" ]]; then
  sudo systemctl disable --now palm-guard || true
  sudo rm -f /usr/local/bin/palm-guard /etc/systemd/system/palm-guard.service
  sudo systemctl daemon-reload
  echo "palm-guard removed."
  exit 0
fi

sudo install -m 755 -o root -g root "$here/palm-guard" /usr/local/bin/palm-guard
sudo install -m 644 -o root -g root "$here/palm-guard.service" /etc/systemd/system/palm-guard.service
sudo systemctl daemon-reload
sudo systemctl enable palm-guard
sudo systemctl restart palm-guard
systemctl --no-pager status palm-guard | head -5
