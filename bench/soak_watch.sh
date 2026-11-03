#!/bin/bash
# T1 soak watcher (controller side). Polls every node every 60 s for boot_id/kernel/uptime/Xid and records any
# unexpected reboot (boot_id change, uptime reset, or node came back on a different kernel = GRUB fallback).
#   soak_watch.sh <ARM> <label: idle|loaded> <minutes>
set -u
ARM=$1; LAB=$2; MIN=$3
HERE=$(cd "$(dirname "$0")" && pwd); R=$HERE/../receipts/$ARM; mkdir -p "$R"
OUT=$R/soak-$LAB.jsonl; SUM=$R/soak-$LAB-summary.json
SSH="ssh -o BatchMode=yes -o ConnectTimeout=8"
resets=0; unreach=0   # bash 3.2 (macOS): no associative arrays; per-node vars via eval
end=$(( $(date +%s) + MIN*60 ))
while [ "$(date +%s)" -lt "$end" ]; do
  for h in 55 56 57 58; do
    l=$($SSH milo@192.168.1.$h 'echo "$(cat /proc/sys/kernel/random/boot_id) $(uname -r) $(cut -d. -f1 /proc/uptime) $(journalctl -k -b 0 --no-pager 2>/dev/null | grep -c "NVRM: Xid") $(awk "/MemAvailable/{print int(\$2/1048576)}" /proc/meminfo) $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)"' 2>/dev/null)
    ts=$(date "+%FT%T%z")
    if [ -z "$l" ]; then unreach=$((unreach+1)); echo "{\"ts\":\"$ts\",\"node\":\"spark${h#5}\",\"reachable\":false}" >> "$OUT"; continue; fi
    set -- $l
    ev=""
    eval "pb=\${BOOT_$h:-}; pk=\${KERN_$h:-}"
    if [ -n "$pb" ] && [ "$pb" != "$1" ]; then ev="REBOOT"; resets=$((resets+1)); fi
    if [ -n "$pk" ] && [ "$pk" != "$2" ]; then ev="$ev KERNEL_CHANGED($pk->$2)"; fi
    eval "BOOT_$h=$1; KERN_$h=$2"
    echo "{\"ts\":\"$ts\",\"node\":\"spark${h#5}\",\"boot_id\":\"$1\",\"kernel\":\"$2\",\"uptime_s\":$3,\"xid\":$4,\"memavail_gib\":$5,\"temp_mC\":\"${6:-}\",\"event\":\"$ev\"}" >> "$OUT"
    [ -n "$ev" ] && echo "$(date '+%F %T') spark${h#5} $ev" | tee -a "$R/soak-events.log"
  done
  sleep 60
done
echo "{\"arm\":\"$ARM\",\"soak\":\"$LAB\",\"minutes\":$MIN,\"resets\":$resets,\"unreachable_polls\":$unreach}" | tee "$SUM"
