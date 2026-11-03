#!/bin/bash
# Stage 1 (per node): move a DGX Spark from 6.17.0-1031 + 595.84 to the stock 580.178.04 driver with prebuilt
# modules for 6.17.0-1032, 7.0.0-1019 and 7.0.0-1024; set GRUB to saved/one-shot with 6.17.0-1032 as fallback.
# Does NOT reboot. Aborts (nothing reboots) on any gate failure.   switch_to_580.sh [--dry-run]
set -euo pipefail
DRY=${1:-}
K=/home/milo/kbench; LOG=$K/logs/switch580-$(date +%Y%m%d-%H%M%S).log; exec > >(tee -a "$LOG") 2>&1
UUID=$(grep -oE 'root=UUID=[a-f0-9-]+' /proc/cmdline | cut -d= -f3)
echo "== $(hostname) $(date -Is) kernel=$(uname -r) driver=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
# gates
[ "$(docker ps -q | wc -l | tr -d ' ')" = 0 ] || { echo "ABORT: containers running"; exit 2; }
n=$(ls $K/rollback-595.84/debs/*.deb 2>/dev/null | wc -l | tr -d ' '); [ "$n" -ge 90 ] || { echo "ABORT: rollback set has $n debs"; exit 2; }
SET="$(cat $K/driver580-set.txt) linux-modules-nvidia-580-open-nvidia-hwe-24.04"
sudo -n apt-get -s install --no-install-recommends --allow-change-held-packages --allow-downgrades $SET > $K/logs/sim580.txt 2>&1
grep -E '^Inst' $K/logs/sim580.txt | grep -iE 'tegra|lowlatency|64k|oracle|dkms|generic|aws|azure|gcp' && { echo "ABORT: foreign kernel/dkms in plan"; exit 2; }
grep -qE '^E:' $K/logs/sim580.txt && { echo "ABORT: apt simulate error"; grep -E '^E:' $K/logs/sim580.txt; exit 2; }
echo "simulate ok: $(grep -cE '^Inst' $K/logs/sim580.txt) inst, $(grep -cE '^Remv' $K/logs/sim580.txt) remv"
[ "$DRY" = "--dry-run" ] && { echo DRY_RUN_OK; exit 0; }

apt-mark showhold > $K/logs/holds-before-580.txt
sudo -n DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --allow-change-held-packages --allow-downgrades $SET > $K/logs/apt580.log 2>&1
echo "apt rc=0; holds now: $(apt-mark showhold | tr '\n' ' ')"
for kv in 6.17.0-1032-nvidia 7.0.0-1019-nvidia 7.0.0-1024-nvidia; do
  v=$(modinfo -k $kv -F version nvidia 2>/dev/null || echo MISSING)
  echo "module $kv nvidia=$v"; [ "$v" = 580.178.04 ] || { echo "ABORT: $kv has no 580.178.04 module (do NOT reboot)"; exit 3; }
done
# GRUB: saved default + visible menu; fallback/default = 6.17.0-1032 (has a 580.178.04 module; 1031 does not)
sudo -n mkdir -p $K/grub-backup && sudo -n cp -a /etc/default/grub.d/zz-milo-default-6.17.cfg $K/grub-backup/ 2>/dev/null || true
sudo -n rm -f /etc/default/grub.d/zz-milo-default-6.17.cfg
printf '# kernel study 2026-11 (Milo): saved default + one-shot test boots via grub-reboot; menu visible\nGRUB_DEFAULT=saved\nGRUB_TIMEOUT=10\nGRUB_TIMEOUT_STYLE=menu\n' | sudo -n tee /etc/default/grub.d/zz-kbench-grub.cfg >/dev/null
sudo -n update-grub > $K/logs/update-grub.log 2>&1
E="gnulinux-advanced-$UUID>gnulinux-6.17.0-1032-nvidia-advanced-$UUID"
sudo -n grep -q "gnulinux-6.17.0-1032-nvidia-advanced-$UUID" /boot/grub/grub.cfg || { echo "ABORT: 1032 entry missing from grub.cfg"; exit 3; }
sudo -n grub-set-default "$E"
echo "grubenv: $(sudo -n grub-editenv list | tr '\n' ' ')"
echo "STAGE1_DONE $(hostname)"
