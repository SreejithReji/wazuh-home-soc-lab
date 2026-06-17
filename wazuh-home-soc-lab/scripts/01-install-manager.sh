#!/usr/bin/env bash
# 01-install-manager.sh
# Installs and starts the Wazuh manager on Ubuntu Server.
# Run on the SIEM server VM.

set -euo pipefail

echo "==> Adding Wazuh GPG key and APT repository"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt update

echo "==> Installing wazuh-manager"
sudo apt-get install -y wazuh-manager

echo "==> Enabling and starting wazuh-manager"
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager

echo "==> Status:"
sudo systemctl status wazuh-manager --no-pager
