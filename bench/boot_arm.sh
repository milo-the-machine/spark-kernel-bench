#!/bin/bash
# Boot all four nodes into one kernel and gate them.   boot_arm.sh <kernel e.g. 7.0.0-1019-nvidia> [--no-kho-off]
# Default kernel (6.17.0-1032) boots normally; any other kernel is a one-shot grub-reboot, so a crash/reset falls
# back to 6.17.0-1032 by itself. --no-kho-off: remove kho=off for that one boot (S1x), restored right after.
set -u
KV=$1; NOKHO=${2:-}
HERE=$(cd "$(dirname "$0")" && pwd)
SSH="ssh -o BatchMode=yes -o ConnectTimeout=8"
NODES="55 56 57 58"
ts() { date '+%F %T'; }
for h in $NODES; do
  $SSH milo@192.168.1.$h "set -e
    [ \$(docker ps -q | wc -l) -eq 0 ] || { echo 'ABORT containers running'; exit 2; }
    v=\$(modinfo -k $KV -F version nvidia); [ \"\$v\" = 580.178.04 ] || { echo \"ABORT module \$v\"; exit 3; }
    U=\$(grep -oE 'root=UUID=[a-f0-9-]+' /proc/cmdline | cut -d= -f3)
    if [ '$NOKHO' = --no-kho-off ]; then sudo -n mv /etc/default/grub.d/nvidia-spark-kho.cfg /home/milo/kbench/nvidia-spark-kho.cfg.off; sudo -n update-grub >/dev/null 2>&1; fi
    if [ '$KV' != 6.17.0-1032-nvidia ]; then sudo -n grub-reboot \"gnulinux-advanced-\$U>gnulinux-$KV-advanced-\$U\"; fi
    sudo -n grub-editenv list | tr '\n' ' '; echo
    sudo -n systemctl reboot" 2>&1 | sed "s/^/$(ts) spark${h#5}: /"
done
echo "$(ts) reboots issued; waiting"
sleep 90
for h in $NODES; do
  for i in $(seq 1 60); do $SSH milo@192.168.1.$h true 2>/dev/null && break; sleep 10; done
  $SSH milo@192.168.1.$h "echo \"\$(uname -r) up=\$(cut -d. -f1 /proc/uptime)s drv=\$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1|head -1) kho=\$(grep -c 'kho=off' /proc/cmdline) cdi_old=\$(grep -c 595.84 /run/cdi/nvidia.yaml 2>/dev/null) cdi_new=\$(grep -c 580.178.04 /run/cdi/nvidia.yaml 2>/dev/null) dri=\$(ls /dev/dri/by-path/pci-000f:01:00.0-card >/dev/null 2>&1 && echo ok || echo MISSING) hca=\$(ls /sys/class/infiniband | tr '\n' ,) sys=\$(systemctl is-system-running)\"
    [ -f /home/milo/kbench/nvidia-spark-kho.cfg.off ] && { sudo -n mv /home/milo/kbench/nvidia-spark-kho.cfg.off /etc/default/grub.d/nvidia-spark-kho.cfg; sudo -n update-grub >/dev/null 2>&1; echo 'kho cfg restored for next boot'; }; true" 2>&1 | sed "s/^/$(ts) spark${h#5}: /"
done
