#!/bin/bash
# Flash the October 2026 DGX Spark firmware (fwupd/LVFS) on one node, then set Display Reserved Memory to 0.5 GB
# via the NvidiaDispFrmSizeRequest UEFI variable. Run from the controller:  fw_node.sh <ip>
# Re-runnable: skips the flash if no capsules are staged. Waits for fwupd after boot.
# Node must have no containers running. Two reboots. Stops at the first failed gate.
set -u
IP=$1; SSH="ssh -o BatchMode=yes -o ConnectTimeout=8 milo@$IP"
HERE=$(cd "$(dirname "$0")" && pwd); L=$HERE/../receipts/firmware-rollout.log
log() { echo "$(date '+%F %T %Z') [$IP] $*" | tee -a "$L"; }
die() { log "ABORT: $*"; exit 1; }
V=/sys/firmware/efi/efivars; G=284e19b9-235f-4aab-ae4c-190456d1bd76
waitup() { sleep 75; for t in $(seq 1 100); do $SSH true 2>/dev/null && return 0; sleep 6; done; return 1; }
fw() { $SSH "sudo -n fwupdmgr get-devices --json 2>/dev/null" | python3 -c "
import json,sys
d=json.load(sys.stdin); print(' '.join(x.get('Version','?') for x in d.get('Devices',[]) if x.get('Name') in ('Embedded Controller','UEFI Device Firmware')))"; }
[ "$($SSH 'docker ps -q | wc -l' | tr -d ' ')" = 0 ] || die "containers running"
log "before: bios=$($SSH 'sudo -n dmidecode -s bios-version') fw=[$(fw)] memtotal=$($SSH "awk '/MemTotal/{print \$2}' /proc/meminfo")"
$SSH 'sudo -n fwupdmgr refresh --force >/dev/null 2>&1; sudo -n fwupdmgr upgrade -y --no-reboot-check 2>&1 | grep -E "Successfully|No updates|error|Error|failed" | sort -u' | tee -a "$L"
n=$($SSH 'sudo -n ls /boot/efi/EFI/UpdateCapsule/ 2>/dev/null | wc -l' | tr -d ' ')
log "capsules staged: $n"
if [ "$n" -gt 0 ]; then
  $SSH 'sudo -n systemctl reboot' 2>/dev/null; log "reboot 1 (flash)"; waitup || die "no SSH after flash reboot (check console, do NOT power-cycle while flashing)"
fi
fwv=""; for t in $(seq 1 30); do fwv=$(fw 2>/dev/null); [ -n "$fwv" ] && break; sleep 5; done; bios=$($SSH 'sudo -n dmidecode -s bios-version'); log "after flash: bios=$bios fw=[$fwv]"
echo "$fwv" | grep -q 0x02009e0f || die "SoC firmware not 0x02009e0f"
echo "$fwv" | grep -q 0x03000d07 || die "EC firmware not 0x03000d07"
$SSH "test -e $V/NvidiaDispFrmStatus-$G" || die "no NvidiaDispFrmStatus variable"
st=$($SSH "sudo -n od -An -tx1 $V/NvidiaDispFrmStatus-$G" | tr -s ' '); log "disp status before: $st"
if ! echo "$st" | grep -q "^ 06 00 00 00 01 00 02 00 00"; then
  $SSH "sudo -n chattr -i $V/NvidiaDispFrmSizeRequest-$G 2>/dev/null; printf '\x07\x00\x00\x00\x01' | sudo -n tee $V/NvidiaDispFrmSizeRequest-$G >/dev/null" || die "efivar write failed"
  $SSH 'sudo -n systemctl reboot' 2>/dev/null; log "reboot 2 (display memory)"; waitup || die "no SSH after reboot 2"
fi
st=$($SSH "sudo -n od -An -tx1 $V/NvidiaDispFrmStatus-$G" | tr -s ' ')
r=$($SSH 'echo "$(uname -r) $(nvidia-smi --query-gpu=driver_version --format=csv,noheader) memtotal=$(awk "/MemTotal/{print \$2}" /proc/meminfo) links=$(cat /sys/class/net/enp1s0f0np0/operstate),$(cat /sys/class/net/enP2p1s0f0np0/operstate) xid=$(sudo -n dmesg | grep -ci xid) userns=$(sysctl -n user.max_user_namespaces) tgt=$(systemctl get-default)"')
log "final: disp=$st $r"
echo "$st" | grep -q "^ 06 00 00 00 01 00 02 00 00" || die "display reservation not 0.5 GB"
echo "$r" | grep -q "^7.0.0-1024-nvidia 580.178.04" || die "kernel/driver changed"
log "NODE DONE"
