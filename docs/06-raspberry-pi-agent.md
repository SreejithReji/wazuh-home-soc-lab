# Raspberry Pi Agent Deployment

The Wazuh **agent** is lightweight software installed on the monitored endpoint (the Pi) that collects local logs/events and forwards them to the manager over an encrypted channel.

> **Architecture note:** unlike the indexer and dashboard (which are x86_64/AMD64-only), the Wazuh **agent** fully supports ARM64 — this is exactly why the SIEM server components live on the x86 Ubuntu VM while only the lightweight agent runs on the Pi.

## 1. Add the Wazuh repository (same as the manager)

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
```

APT automatically serves the `arm64` build of the package since that's the Pi's native architecture — no special flags needed.

## 2. Install, pointing at the manager's IP

```bash
sudo WAZUH_MANAGER='192.168.1.119' apt-get install wazuh-agent -y
```

Setting `WAZUH_MANAGER` as an environment variable before the install lets the package's post-install configuration script auto-populate `/var/ossec/etc/ossec.conf` with the manager's address — no manual config file editing needed.

## 3. Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
sudo systemctl status wazuh-agent
```

A healthy agent shows these processes running:
```
wazuh-execd, wazuh-agentd, wazuh-syscheckd, wazuh-logcollector, wazuh-modulesd
```

## 4. Verify enrollment

**From the Pi itself:**
```bash
sudo cat /var/ossec/var/run/wazuh-agentd.state
```
Look for `status='connected'`. Example real output from this lab:
```
status='connected'
last_keepalive='2026-06-17 19:09:08'
last_ack='2026-06-17 19:09:16'
msg_count='660'
msg_sent='663'
```

**From the manager:**
```bash
sudo /var/ossec/bin/agent_control -l
```
```
ID: 001, Name: sree-pi-lab, IP: any, Active
```

**From the dashboard:** Agents section → the Pi appears listed with status, IP, OS, registration date, and last keep-alive — all queryable/filterable for investigation.

## Result

| Field | Value |
|---|---|
| Agent ID | 001 |
| Hostname | sree-pi-lab |
| IP | 192.168.1.63 |
| Version | Wazuh v4.14.5 (matches manager) |
| OS | Debian GNU/Linux 13 |
| Status | Active |
