#!/usr/bin/env bash
# 05-install-pi-agent.sh
# Installs the Wazuh agent on a Raspberry Pi (or any ARM64/Debian-based target).
# Run ON THE TARGET DEVICE, not the SIEM server.
#
# Edit MANAGER_IP below before running.

set -euo pipefail

MANAGER_IP="192.168.1.119"   # <-- CHANGE ME: your Wazuh manager's LAN IP

echo "==> Adding Wazuh GPG key and APT repository"
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update

echo "==> Installing wazuh-agent (apt automatically resolves the arm64 build)"
sudo WAZUH_MANAGER="${MANAGER_IP}" apt-get install -y wazuh-agent

echo "==> Enabling and starting wazuh-agent"
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent

echo "==> Agent connection state:"
sudo cat /var/ossec/var/run/wazuh-agentd.state

echo "==> Done. Verify from the manager with: sudo /var/ossec/bin/agent_control -l"
