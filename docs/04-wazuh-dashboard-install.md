# Wazuh Dashboard Installation

The dashboard is the web UI analysts actually use — it queries the indexer and renders alerts, agent status, and visualizations.

## 1. Install

```bash
sudo apt-get install wazuh-dashboard
```

Like the indexer, this does **not** auto-start — certificates and config must be in place first.

## 2. Deploy certificates

The dashboard uses its own node certificate (generated alongside the others in the indexer setup step):

```bash
sudo mkdir -p /etc/wazuh-dashboard/certs
sudo cp wazuh-certificates/dashboard.pem /etc/wazuh-dashboard/certs/
sudo cp wazuh-certificates/dashboard-key.pem /etc/wazuh-dashboard/certs/
sudo cp wazuh-certificates/root-ca.pem /etc/wazuh-dashboard/certs/

sudo chmod 500 /etc/wazuh-dashboard/certs
sudo bash -c 'chmod 400 /etc/wazuh-dashboard/certs/*'
sudo chown -R wazuh-dashboard:wazuh-dashboard /etc/wazuh-dashboard/certs
```

## 3. Configure `opensearch_dashboards.yml`

The shipped default config already has the correct cert paths and SSL settings, **but is missing the indexer authentication credentials** — `opensearch.username` and `opensearch.password` are commented out by default:

```bash
sudo sed -i 's/#opensearch.username:/opensearch.username: kibanaserver/' /etc/wazuh-dashboard/opensearch_dashboards.yml
sudo sed -i 's/#opensearch.password:/opensearch.password: kibanaserver/' /etc/wazuh-dashboard/opensearch_dashboards.yml
```

`kibanaserver`/`kibanaserver` is the default internal service account created automatically during the indexer's security initialization step — it's specifically meant for the dashboard's backend-to-indexer communication (distinct from the human-facing `admin` login).

Full sanitized file: [`configs/wazuh-dashboard/opensearch_dashboards.yml`](../configs/wazuh-dashboard/opensearch_dashboards.yml)

## 4. Start the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
sudo systemctl status wazuh-dashboard
```

> **Note:** systemd reports `active (running)` quickly, but the dashboard is a Node.js application bundling/initializing internally — it can take **30–90 seconds** before it's actually responsive to browser connections. Don't assume failure if the page doesn't load immediately.

## 5. Access

Browse to `https://<dashboard-ip>/` from any machine on the same network. You'll get a browser TLS warning since these are self-signed certificates (signed by the lab's own root CA, not a public CA) — this is expected; proceed past the warning.

Default login: `admin` / `admin` (rotate before any non-lab use).

## 6. Health check

On first login, Wazuh runs an automatic health check (`/app/wz-home#/health-check`) verifying:
- API connection
- API version
- Alerts index pattern
- Monitoring index pattern
- Statistics index pattern

If **"Check alerts index pattern"** fails with *"No template found for the selected index-pattern title [wazuh-alerts-*]"*, this means Filebeat hasn't been configured/started yet — see [Filebeat Configuration](05-filebeat-configuration.md). The alerts index template is created by Filebeat on its first successful start, not by the indexer or dashboard installation itself.
