# Wazuh Indexer Installation & Certificate Generation

The Wazuh indexer (an OpenSearch fork) is the storage and search backend — alerts shipped by Filebeat land here, and the dashboard queries it. Unlike the manager, the indexer **requires TLS certificates and explicit configuration before it will start successfully**.

## 1. Install the package

```bash
sudo apt-get install wazuh-indexer
```

> **Disk space note:** this package alone needs ~875MB, and the full single-node stack (manager + indexer + dashboard) needs several GB of headroom. If your VM disk was sized too small at creation, this is where you'll hit `No space left on device`. See [Network & Systems Troubleshooting](08-network-troubleshooting.md#disk-exhaustion) for the live LVM resize fix used in this lab.

The post-install script deliberately does **not** auto-start the service:
```
### NOT starting on installation, please execute the following statements to configure wazuh-indexer
### service to start automatically using systemd
 sudo systemctl daemon-reload
 sudo systemctl enable wazuh-indexer.service
### You can start wazuh-indexer service by executing
 sudo systemctl start wazuh-indexer.service
```

## 2. Download the certificate tool and config template

```bash
curl -sO https://packages.wazuh.com/4.14/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.14/config.yml
```

> **Gotcha:** the generic `4.x` path alias (used for the APT repo) does **not** work for these direct file downloads — it returns an `AccessDenied` XML error instead of the real file. Use the exact dot-release version (matching your installed Wazuh version) in the URL, e.g. `4.14`.

## 3. Edit `config.yml` for a single-node deployment

For an all-in-one single-node setup, the **same IP address** (this VM's LAN IP) is used for the indexer, server, and dashboard node entries:

```yaml
nodes:
  indexer:
    - name: node-1
      ip: "192.168.1.119"
  server:
    - name: wazuh-1
      ip: "192.168.1.119"
  dashboard:
    - name: dashboard
      ip: "192.168.1.119"
```

> **Important — use the host's real LAN IP, not a NAT-internal address.** If the VM is on a VirtualBox NAT adapter, it will have an internal-only IP (e.g. `10.0.2.15`) that other devices on your network (like a Raspberry Pi target) can't reach. Switch the VM to a **Bridged Adapter** *before* generating certificates, since certificates are bound to the IP at generation time — changing the IP afterward means regenerating everything.

See the sanitized real file used in this lab: [`configs/cert-generation/config.yml`](../configs/cert-generation/config.yml)

## 4. Generate all certificates

```bash
chmod +x wazuh-certs-tool.sh
sudo bash ./wazuh-certs-tool.sh -A
```

`-A` generates certificates for **all** node types (indexer, server/Filebeat, dashboard, admin, root CA) in one pass — appropriate for a single-node deployment where everything lives on one machine. Output lands in `./wazuh-certificates/`:

```
admin.pem, admin-key.pem
root-ca.pem, root-ca.key
node-1.pem, node-1-key.pem      ← indexer
wazuh-1.pem, wazuh-1-key.pem    ← server / Filebeat
dashboard.pem, dashboard-key.pem
```

## 5. Deploy the indexer's certificates

```bash
sudo mkdir -p /etc/wazuh-indexer/certs
sudo cp wazuh-certificates/node-1.pem /etc/wazuh-indexer/certs/indexer.pem
sudo cp wazuh-certificates/node-1-key.pem /etc/wazuh-indexer/certs/indexer-key.pem
sudo cp wazuh-certificates/admin.pem /etc/wazuh-indexer/certs/
sudo cp wazuh-certificates/admin-key.pem /etc/wazuh-indexer/certs/
sudo cp wazuh-certificates/root-ca.pem /etc/wazuh-indexer/certs/

sudo chmod 500 /etc/wazuh-indexer/certs
sudo bash -c 'chmod 400 /etc/wazuh-indexer/certs/*'
sudo chown -R wazuh-indexer:wazuh-indexer /etc/wazuh-indexer/certs
```

> **Gotcha — shell glob expansion happens *before* sudo runs.** Once the certs directory is locked to `500` (owner-only), your own shell can no longer expand `/etc/wazuh-indexer/certs/*` to list files — because globbing happens in your *own* user's shell process, before `sudo` elevates. The fix is to run the whole chmod **inside** a root shell: `sudo bash -c 'chmod 400 /etc/wazuh-indexer/certs/*'`.

## 6. Verify `opensearch.yml`

The package ships `/etc/wazuh-indexer/opensearch.yml` **already pre-templated** to match the certs-tool's default naming conventions (`node-1`, default certificate Distinguished Names). In this lab, **no manual edits were required** — the defaults already lined up correctly because the node name in `config.yml` (`node-1`) matched what was used to generate certs. Always `cat` the file first to confirm before assuming changes are needed.

See: [`configs/wazuh-indexer/opensearch.yml`](../configs/wazuh-indexer/opensearch.yml)

## 7. Start the indexer

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer
sudo systemctl status wazuh-indexer
```

## 8. Initialize the security index

This is a **mandatory one-time step** — without it, the indexer runs but rejects authenticated requests:

```bash
sudo /usr/share/wazuh-indexer/bin/indexer-security-init.sh
```

Look for `Clusterstate: GREEN` and `Done with success` at the end of the output.

## 9. Verify

```bash
curl -k -u admin:admin https://<indexer-ip>:9200
```

Expected response:
```json
{
  "name" : "node-1",
  "cluster_name" : "wazuh-cluster",
  "version" : { "number" : "7.10.2", ... },
  "tagline" : "The OpenSearch Project: https://opensearch.org/"
}
```

(Default credentials `admin`/`admin` should be rotated before any non-lab use — see Wazuh's password management tooling.)
