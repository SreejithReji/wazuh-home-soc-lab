# Wazuh Manager Installation

The Wazuh manager is the analysis engine — it receives logs/events (from its own host and from remote agents), runs them through its decoder and rule engine, and generates alerts.

## 1. Add the Wazuh GPG key and APT repository

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring \
  --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | \
  sudo tee /etc/apt/sources.list.d/wazuh.list

sudo apt update
```

> **Gotcha:** the repo line must read `stable main` (two separate fields — distribution and component) separated by a space. A typo here (e.g. `stable.main` with a period) produces `apt update` errors like:
> ```
> E: Malformed entry 1 in list file /etc/apt/sources.list.d/wazuh.list (Component)
> ```

## 2. Install the manager

```bash
sudo apt-get install wazuh-manager
```

Unlike the indexer/dashboard, the manager works immediately after install with no certificate/config setup required — it starts ready to receive local and remote agent logs.

## 3. Enable and start

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager
sudo systemctl status wazuh-manager
```

A healthy startup shows all of these processes running under the service's cgroup:

```
wazuh-authd, wazuh-db, wazuh-execd, wazuh-analysisd, wazuh-syscheckd,
wazuh-remoted, wazuh-logcollector, wazuh-monitord, wazuh-modulesd
```

plus the API scripts (`wazuh_apid.py`).

## Listing connected agents

Once agents are enrolled (see [Raspberry Pi Agent Deployment](06-raspberry-pi-agent.md)):

```bash
sudo /var/ossec/bin/agent_control -l
```

Example output from this lab:
```
Wazuh agent_control. List of available agents:
   ID: 000, Name: wazuh-siem (server), IP: 127.0.0.1, Active/Local
   ID: 001, Name: sree-pi-lab, IP: any, Active
```
