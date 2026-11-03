#!/bin/bash
# Put a DGX Spark on the stock track after the kernel study: 7.0.0-1024 + 580.178.04 via the HWE meta packages,
# no local GRUB override, no apt holds. Does NOT reboot.   finalize_stock_1024.sh [--dry-run]
set -euo pipefail
DRY=${1:-}; K=/home/milo/kbench; mkdir -p $K/logs; LOG=$K/logs/finalize-$(date +%Y%m%d-%H%M%S).log
exec > >(tee -a "$LOG") 2>&1
echo "== $(hostname) $(date '+%F %T %Z') kernel=$(uname -r)"
META="linux-image-nvidia-hwe-24.04 linux-headers-nvidia-hwe-24.04 linux-modules-nvidia-fs-nvidia-hwe-24.04 linux-modules-nvidia-580-open-nvidia-hwe-24.04"
sudo -n apt-get -s install --no-install-recommends --allow-change-held-packages $META > $K/logs/sim-final.txt 2>&1
grep -E '^Inst' $K/logs/sim-final.txt | grep -iE 'tegra|lowlatency|64k|oracle|dkms|aws|azure|gcp|595' && { echo "ABORT: unexpected package in plan"; exit 2; }
grep -qE '^E:' $K/logs/sim-final.txt && { echo "ABORT apt"; grep '^E:' $K/logs/sim-final.txt; exit 2; }
echo "plan: $(grep -E '^(Inst|Remv)' $K/logs/sim-final.txt | sed -E 's/ \[.*//; s/ \(([^ ]+) .*/ \1/' | tr '\n' ';')"
[ "$DRY" = --dry-run ] && { echo DRY_RUN_OK; exit 0; }
apt-mark showhold > $K/logs/holds-before-final.txt
sudo -n apt-mark unhold $(apt-mark showhold) >/dev/null 2>&1 || true
sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $META > $K/logs/apt-final.log 2>&1
echo "holds now: [$(apt-mark showhold | tr '\n' ' ')]"
v=$(modinfo -k 7.0.0-1024-nvidia -F version nvidia); [ "$v" = 580.178.04 ] || { echo "ABORT: 1024 module $v"; exit 3; }
sudo -n rm -f /etc/default/grub.d/zz-kbench-grub.cfg
sudo -n grub-editenv - unset saved_entry next_entry
sudo -n update-grub > $K/logs/update-grub-final.log 2>&1
first=$(sudo -n awk '/^menuentry /{f=1} f && /linux[ \t]+\/boot\/vmlinuz/{print $2; exit}' /boot/grub/grub.cfg)
echo "first boot entry kernel: $first"; [ "$first" = /boot/vmlinuz-7.0.0-1024-nvidia ] || { echo "ABORT: default boot is $first"; exit 3; }
echo "grub.d: $(ls /etc/default/grub.d | tr '\n' ' ')"; echo "grubenv: $(sudo -n grub-editenv list | tr '\n' ' ')"
echo "FINAL_DONE $(hostname)"
