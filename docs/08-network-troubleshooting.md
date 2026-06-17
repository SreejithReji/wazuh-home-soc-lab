# Network & Systems Troubleshooting Deep-Dive

This lab generated several genuine troubleshooting scenarios. They're documented in detail here because **the diagnostic process is the most transferable skill** — more so than any individual fix.

---

## Disk Exhaustion

### Symptom
Mid-way through installing `wazuh-indexer` (874MB package):
```
Error writing to file - write (28: No space left on device)
E: Unable to fetch some archives, maybe run apt-get update or try with --fix-missing?
```

### Diagnosis
```bash
df -h
```
```
Filesystem                          Size  Used Avail Use% Mounted on
/dev/mapper/ubuntu--vg-ubuntu--lv     24G   24G     0 100% /
```
Root filesystem completely full at exactly 24GB — suspicious, since that's suspiciously close to a default install size, not a deliberately chosen one.

```bash
sudo vgs   # VG size <48.00g, VFree 24.00g
sudo lvs   # LV size <24.00g
sudo pvs   # Physical disk: <48.00g, PFree 24.00g
```

**Root cause:** the underlying virtual disk was actually **48GB**, but the Ubuntu Server installer only allocated **24GB** to the root logical volume by default, leaving the other 24GB sitting unallocated in the volume group the entire time. This is a known quirk of the Ubuntu Server LVM-based installer not always claiming the full disk automatically.

### Fix (live, no reboot, no data loss)
```bash
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
```
Result: root filesystem grew from 24GB → 48GB with 22GB immediately available, while the system stayed fully online throughout.

**Takeaway:** always check `vgs`/`lvs`/`pvs` before assuming a disk is genuinely full — on LVM-based systems, "no space left" can mean "space exists but was never allocated," which is a very different (and much easier) fix than resizing a virtual disk.

---

## MTU / Path MTU Discovery Investigation

### Symptom
Package downloads inside the VM crawled at ~20-60 KB/s despite the host machine measuring 990 Mbps on the same network. Latency (`ping`) was consistently healthy (~9-12ms, 0% loss) — ruling out a simple connectivity or congestion problem.

### Diagnostic path
1. Ruled out CPU starvation (VM had 3 cores at 100% cap — confirmed via VirtualBox settings)
2. Ruled out NIC emulation type (switching `Intel PRO/1000` → `virtio-net` made no difference)
3. `ethtool <interface>` returned `Speed: Unknown!` / `Duplex: Unknown!` — a dead end, since virtualized NICs have no real PHY layer to report on
4. Tested for fragmentation/MTU issues directly:
```bash
ping -c 5 -M do -s 1472 8.8.8.8
```
```
From 192.168.1.1 icmp_seq=1 Frag needed and DF set (mtu = 1492)
```

**Finding:** the actual path only supports an MTU of 1492, not the standard 1500 the interface was using — an 8-byte difference consistent with **PPPoE overhead** (common on UK ISP connections). Large packets sent with the "Don't Fragment" flag set were being rejected outright by the router.

### Fix attempted
```bash
sudo ip link set dev enp0s3 mtu 1492
```
Confirmed via:
```bash
ping -c 5 -M do -s 1464 8.8.8.8   # 1464 + 28 bytes headers = 1492, fits exactly
```
0% packet loss after the change — but a follow-up `wget` throughput test showed only marginal improvement (57 KB/s vs. 38 KB/s before).

### Conclusion
The MTU mismatch was real and worth fixing (and a good case study in PMTUD black-holing — where ICMP "fragmentation needed" messages can get silently dropped along some paths, causing exactly this kind of "healthy ping, terrible throughput" symptom). However, it was **not the dominant cause** of the slow downloads in this case. The practical workaround that actually resolved throughput was switching the VM's network adapter to **NAT** for bulk downloads, then back to **Bridged** for LAN-dependent operations (dashboard access, agent communication) — strongly suggesting the deeper cause was **router-side QoS/throttling of an unrecognized device's MAC address** when freshly bridged, a common default behavior on consumer routers that's harder to diagnose remotely without access to the router's admin panel.

**Takeaway:** not every diagnosed issue is *the* root cause — documenting a real, partially-effective fix alongside the actual workaround is more honest (and more useful to a reader) than claiming a single clean resolution.

---

## TLS Hostname Verification Mismatch (Filebeat → Indexer)

See [Filebeat Configuration](05-filebeat-configuration.md#tls-troubleshooting) for the full write-up — certificate issued for the LAN IP, but the default config connected via `127.0.0.1`, triggering a hostname mismatch on an otherwise successful TLS handshake.

---

## VirtualBox Bridged-over-Wi-Fi Instability

Observed throughout the build: bridging a VM's virtual NIC through the host's **Wi-Fi** adapter (as opposed to Ethernet) produced inconsistent throughput, even with otherwise identical VM/network settings. This is a [known weak point](https://en.wikipedia.org/wiki/Bridging_(networking)) of software bridging over wireless interfaces, since the host's Wi-Fi driver has to present and manage two distinct MAC addresses (the host's own and the VM's) over a single radio — something Ethernet handles natively without issue. Where available, bridging over a wired connection is the more reliable choice for lab environments like this one.
