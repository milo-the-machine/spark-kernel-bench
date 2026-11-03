#!/bin/bash
# Headless A/B on Sparks 5-8 (same boot, same kernel 7.0.0-1024 + 580.178.04):
#   H0 = graphical.target (GDM/GNOME running), H1 = after `systemctl isolate multi-user.target`.
# Lane must be stopped first. Does not reboot, does not change the default target.
set -u
HERE=$(cd "$(dirname "$0")" && pwd); R=$HERE/../receipts; L=$R/headless-ab.log
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"; N="55 56 57 58"
log() { echo "$(date '+%F %T %Z') $*" | tee -a "$L"; }
snap() {  # $1 = arm dir
  mkdir -p "$R/$1"
  for h in $N; do $SSH milo@192.168.1.$h 'echo "{\"host\":\"$(hostname)\",\"target_active\":\"$(systemctl is-active graphical.target)\",\"gdm\":\"$(systemctl is-active gdm)\",\"memavail_kib\":$(awk "/MemAvailable/{print \$2}" /proc/meminfo),\"memfree_kib\":$(awk "/MemFree/{print \$2}" /proc/meminfo),\"procs\":$(ps -e --no-headers | wc -l),\"mlx5_irq_cpus\":\"$(for i in $(grep -E "mlx5_comp" /proc/interrupts | cut -d: -f1 | head -8); do cat /proc/irq/$i/effective_affinity_list; done | tr "\n" " ")\"}"'; done > "$R/$1/state.jsonl"
}
log "HEADLESS A/B start"
for h in $N; do c=$($SSH milo@192.168.1.$h 'docker ps -q | wc -l' | tr -d ' '); [ "$c" = 0 ] || { log "ABORT .$h has $c containers"; exit 1; }; done
for h in $N; do $SSH milo@192.168.1.$h 'sync; echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null'; done
snap H0-graphical-1024; log "H0 state: $(tr '\n' ' ' < $R/H0-graphical-1024/state.jsonl | cut -c1-400)"
bash "$HERE/run_fabric.sh" H0-graphical-1024 3 >/dev/null 2>&1; log "H0 fabric done"
for h in $N; do $SSH milo@192.168.1.$h 'sudo -n systemctl isolate multi-user.target' 2>&1 | tail -1; done
sleep 20
for h in $N; do $SSH milo@192.168.1.$h 'sync; echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null'; done
snap H1-multiuser-1024; log "H1 state: $(tr '\n' ' ' < $R/H1-multiuser-1024/state.jsonl | cut -c1-400)"
grep -q '"gdm":"active"' "$R/H1-multiuser-1024/state.jsonl" && { log "ABORT: gdm still active after isolate"; exit 1; }
bash "$HERE/run_fabric.sh" H1-multiuser-1024 3 >/dev/null 2>&1; log "H1 fabric done"
log "HEADLESS A/B DONE"
