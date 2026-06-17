#!/usr/bin/env bash
# 06-troubleshooting-helpers.sh
# Standalone diagnostic/fix snippets referenced in docs/08-network-troubleshooting.md.
# This is a reference script, not meant to be run end-to-end blindly —
# read docs/08-network-troubleshooting.md first to understand which section applies.

# ---------------------------------------------------------------------------
# Section 1: Live LVM root filesystem extension (fixes "No space left on
# device" when the install disk was undersized by the OS installer)
# ---------------------------------------------------------------------------
lvm_extend_root() {
  echo "Current state:"
  df -h /
  sudo vgs
  sudo lvs
  sudo pvs

  echo "Extending logical volume to use all free space in the volume group..."
  sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv

  echo "Growing the filesystem to match (ext4 assumed; use xfs_growfs for XFS):"
  sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

  echo "New state:"
  df -h /
}

# ---------------------------------------------------------------------------
# Section 2: Path MTU Discovery diagnostic
# Run this if you see healthy ping latency but very slow bulk download speeds.
# ---------------------------------------------------------------------------
diagnose_mtu() {
  TARGET="${1:-8.8.8.8}"
  echo "Testing for fragmentation/PMTUD issues against ${TARGET}..."
  ping -c 5 -M do -s 1472 "${TARGET}" || true
  echo
  echo "If you saw 'Frag needed and DF set (mtu = XXXX)', your path MTU is XXXX."
  echo "Apply with: sudo ip link set dev <interface> mtu <XXXX>"
  echo "Then re-verify with a packet sized exactly to fit (target_mtu - 28 bytes):"
  echo "  ping -c 5 -M do -s <target_mtu - 28> ${TARGET}"
}

# ---------------------------------------------------------------------------
# Section 3: Quick raw throughput test, independent of any particular
# package mirror (useful for isolating "is it my network or the repo?")
# ---------------------------------------------------------------------------
quick_speed_test() {
  wget -4 -O /dev/null http://speedtest.tele2.net/10MB.zip
}

echo "This file defines functions: lvm_extend_root, diagnose_mtu, quick_speed_test"
echo "Source it and call the relevant function, e.g.:"
echo "  source 06-troubleshooting-helpers.sh && diagnose_mtu 8.8.8.8"
