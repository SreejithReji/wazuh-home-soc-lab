#!/usr/bin/env bash
# 02-install-indexer.sh
# Installs the Wazuh indexer, generates certificates, and initializes security.
#
# IMPORTANT: edit LAB_IP below to match your own SIEM server's LAN IP before running.
# Also ensure your VM's network adapter is set to Bridged (not NAT) BEFORE
# running this script, since certificates are bound to this IP at generation time.

set -euo pipefail

LAB_IP="192.168.1.119"          # <-- CHANGE ME
WAZUH_VERSION="4.14"             # match your installed Wazuh dot-release

echo "==> Installing wazuh-indexer"
sudo apt-get install -y wazuh-indexer

echo "==> Downloading cert tool and config template"
curl -sO "https://packages.wazuh.com/${WAZUH_VERSION}/wazuh-certs-tool.sh"
curl -sO "https://packages.wazuh.com/${WAZUH_VERSION}/config.yml"

echo "==> Patching config.yml with LAB_IP=${LAB_IP}"
sed -i "s/<indexer-node-ip>/${LAB_IP}/; s/<wazuh-manager-ip>/${LAB_IP}/; s/<dashboard-node-ip>/${LAB_IP}/" config.yml

echo "==> Generating certificates"
chmod +x wazuh-certs-tool.sh
sudo bash ./wazuh-certs-tool.sh -A

echo "==> Deploying indexer certificates"
sudo mkdir -p /etc/wazuh-indexer/certs
sudo cp wazuh-certificates/node-1.pem /etc/wazuh-indexer/certs/indexer.pem
sudo cp wazuh-certificates/node-1-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
sudo cp wazuh-certificates/admin.pem /etc/wazuh-indexer/certs/
sudo cp wazuh-certificates/admin-key.pem /etc/wazuh-indexer/certs/
sudo cp wazuh-certificates/root-ca.pem /etc/wazuh-indexer/certs/

sudo chmod 500 /etc/wazuh-indexer/certs
sudo bash -c 'chmod 400 /etc/wazuh-indexer/certs/*'
sudo chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs

echo "==> Starting wazuh-indexer"
sudo systemctl daemon-reload
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer

echo "==> Initializing security index (one-time)"
sudo /usr/share/wazuh-indexer/bin/indexer-security-init.sh

echo "==> Verifying"
curl -k -u admin:admin "https://${LAB_IP}:9200"
