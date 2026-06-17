#!/usr/bin/env bash
# 04-install-filebeat.sh
# Installs and configures Filebeat to ship manager alerts into the indexer.
# Run AFTER 02-install-indexer.sh, from the same working directory.

set -euo pipefail

WAZUH_VERSION="4.14"
WAZUH_FULL_VERSION="v4.14.5"   # exact tag for the GitHub-hosted alert template

echo "==> Installing filebeat and pulling the Wazuh-preconfigured filebeat.yml"
sudo apt-get install -y filebeat
sudo curl -so /etc/filebeat/filebeat.yml "https://packages.wazuh.com/${WAZUH_VERSION}/tpl/wazuh/filebeat/filebeat.yml"

echo "==> Deploying Filebeat certificates (reuses the 'server' node cert: wazuh-1)"
sudo mkdir -p /etc/filebeat/certs
sudo cp wazuh-certificates/wazuh-1.pem /etc/filebeat/certs/filebeat.pem
sudo cp wazuh-certificates/wazuh-1-key.pem /etc/filebeat/certs/filebeat-key.pem
sudo cp wazuh-certificates/root-ca.pem /etc/filebeat/certs/

sudo chmod 500 /etc/filebeat/certs
sudo bash -c 'chmod 400 /etc/filebeat/certs/*'
sudo chown -R root:root /etc/filebeat/certs

echo "==> Storing indexer credentials in the Filebeat keystore"
sudo filebeat keystore create --force
echo admin | sudo filebeat keystore add username --stdin --force
echo admin | sudo filebeat keystore add password --stdin --force

echo "==> Downloading the alerts index template"
sudo curl -so /etc/filebeat/wazuh-template.json \
  "https://raw.githubusercontent.com/wazuh/wazuh/${WAZUH_FULL_VERSION}/extensions/elasticsearch/7.x/wazuh-template.json"
sudo chmod go+r /etc/filebeat/wazuh-template.json

echo "==> Installing the Wazuh module for Filebeat"
sudo curl -s "https://packages.wazuh.com/${WAZUH_VERSION}/filebeat/wazuh-filebeat-0.5.tar.gz" | sudo tar -xvz -C /usr/share/filebeat/module

echo "==> Relaxing TLS verification to certificate-only (avoids 127.0.0.1 vs LAN-IP hostname mismatch)"
sudo sed -i '/ssl.key:/a\  ssl.verification_mode: certificate' /etc/filebeat/filebeat.yml

echo "==> Starting filebeat"
sudo systemctl daemon-reload
sudo systemctl enable filebeat
sudo systemctl start filebeat

echo "==> Testing output connectivity"
sudo filebeat test output
