# Hardware & VM Planning

## Goals

The lab needed to simulate a minimal but realistic SOC environment: a monitored endpoint, an attacker, and a central SIEM — on consumer-grade hardware, within a single laptop's resource budget.

## Hardware Decisions

| Decision | Choice | Reasoning |
|---|---|---|
| Target device | Raspberry Pi 5 (4GB) — iRasptek Starter Kit | A real physical device generating real logs is more representative than another VM. The 4GB model (~£170) was chosen over the 8GB (~£220+) since the Pi only needs to run lightweight services (SSH, Apache) for this lab — not heavy workloads. |
| Network switch | TP-Link TL-SG608E (managed) | A managed switch allows VLAN segmentation in future lab phases; an unmanaged switch (e.g. TL-SG105S) was ruled out for this reason. |
| Case/cooling | Included in iRasptek kit | A separate case (e.g. GeeekPi tower, ElectroCookie) was deemed redundant since the starter kit already bundles a case and active cooler. |
| Hypervisor host | MSI Prestige 15, 16GB RAM | Existing laptop; RAM is the binding constraint for how many VMs can run simultaneously. |

## VM Resource Allocation

With 16GB total host RAM, the allocation plan was:

| VM | RAM | Purpose |
|---|---|---|
| Wazuh SIEM (Ubuntu Server) | 6GB | Runs Manager + Indexer + Dashboard simultaneously (single-node, all-in-one on one VM) |
| Kali Linux | 2GB | Attacker — doesn't need much RAM for Nmap/Hydra/Metasploit-class tooling |
| *(reserved)* | 4GB | Left for the Windows host OS itself, to avoid starving the host |

A Windows Server VM (for AD-based attack scenarios — Kerberoasting, Golden Ticket, etc.) was deliberately **not** added at this stage, since it would exceed the available RAM budget. This is flagged as a future hardware-upgrade-dependent roadmap item.

## Software Versions Chosen

| Software | Version | Note |
|---|---|---|
| Ubuntu Server | 22.04.5 LTS | Specifically **not** 24.04 or 26.04 — newer releases had compatibility concerns with the Wazuh installer/packages at time of build |
| Kali Linux | 2026.1 (VirtualBox OVA) | Latest available attacker distro at time of build |
| Raspberry Pi OS | Lite 64-bit (Debian 13 "trixie") | Headless/Lite edition — no desktop environment needed for a target server |
| Wazuh | 4.14.5 | Latest stable at time of build; **version must match exactly between manager, indexer, dashboard, and agent** to avoid compatibility issues |

## Why Manual Component Installation, Not the All-in-One Script

Wazuh provides a `wazuh-install.sh` assisted installer that automates the entire stack. This lab deliberately avoided it in favor of installing the manager, indexer, dashboard, and Filebeat as **separate, individually-configured steps**. The reasoning:

1. **Genuine understanding over convenience.** An automated script hides exactly the kind of internals (certificate trust chains, index templates, the security plugin's role/user model) that are valuable to actually understand for SOC work.
2. **Portfolio depth.** Being able to explain *why* each step is needed — not just that a script ran successfully — is a stronger interview signal.
3. **Troubleshooting practice.** Manual installs surface real configuration problems (see [Network Troubleshooting](08-network-troubleshooting.md)) that an automated script would silently handle, and working through them builds genuinely transferable skills.
