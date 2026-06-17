# Kali Attacker VM Setup

## 1. Import the OVA

Kali Linux is distributed as a pre-built VirtualBox OVA, downloaded as a `.7z` archive:

1. Extract `kali-linux-2026.1-virtualbox-amd64.7z` with 7-Zip to get the `.ova` file
2. VirtualBox → **File → Import Appliance** → select the `.ova`
3. Set RAM allocation to **2GB** (sufficient for Nmap/Hydra-class tooling in this lab; not running Metasploit's full database services concurrently)

## 2. Networking — Bridged Adapter

For Kali to actually reach the Pi target (a physical device on the home LAN, not inside any VirtualBox-internal network), its adapter must be set to **Bridged**, matching the same mode used for the Wazuh SIEM VM:

- Settings → Network → Adapter 1 → Attached to: **Bridged Adapter**
- Name: the host's active network interface (Wi-Fi or Ethernet)

## 3. Default credentials

Recent Kali VirtualBox images default to:
- Username: `kali`
- Password: `kali`

## 4. Connectivity verification

```bash
ip a
ping -c 4 <pi-ip>
ping -c 4 <wazuh-manager-ip>
```

Confirmed in this lab: Kali received `192.168.1.110` on the same `/24` as the Pi (`192.168.1.63`) and the Wazuh manager (`192.168.1.119`), with 0% packet loss to both — confirming all three machines share one flat LAN segment, which is required for the attack simulations to actually reach their targets.

## What Kali is used for in this lab

See [Attack Simulations](../attack-simulations/) for the actual exercises run from this VM:
- Nmap reconnaissance scanning
- Hydra SSH brute-force attacks

Both are standard tools pre-installed on Kali — no additional setup required beyond the VM itself.
