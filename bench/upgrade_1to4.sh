#!/bin/bash
# Upgrade Sparks 1-4 (production SGLang lane) to stock 7.0.0-1024 + 580.178.04, same gates as 5-8.
# Order: repack rollback -> stop lane (head, workers, nfs) -> switch dry-run -> switch -> finalize -> reboot
# -> verify -> start nfs, workers, head -> verify lane.  Any failure before the reboot leaves 595.84 in place.
set -u
HERE=$(cd "$(dirname "$0")" && pwd); L=$HERE/../receipts/upgrade-1to4.log
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"
log() { echo "$(date '+%F %T %Z') $*" | tee -a "$L"; }
die() { log "ABORT: $*"; exit 1; }
N="51 52 53 54"
log "UPGRADE 1-4 start"
for h in $N; do rsync -a "$HERE/" milo@192.168.1.$h:/home/milo/kbench/ || die "rsync .$h"; done
for h in $N; do $SSH milo@192.168.1.$h 'bash /home/milo/kbench/repack_rollback.sh 2>&1 | tail -1' | tee -a "$L" | grep -q REPACKED || die "repack .$h"; done
$SSH milo@192.168.1.51 'docker inspect dsv41-head dsv41-nfs' > "$HERE/../receipts/prod-1to4-inspect-pre.json"
for h in 52 53 54; do $SSH milo@192.168.1.$h 'docker inspect dsv41-worker' >> "$HERE/../receipts/prod-1to4-inspect-pre.json"; done
log "stopping production lane (head -> workers -> nfs, kept)"
$SSH milo@192.168.1.51 'docker stop -t 60 dsv41-head >/dev/null' || die "stop head"
for h in 52 53 54; do $SSH milo@192.168.1.$h 'docker stop -t 60 dsv41-worker >/dev/null' || die "stop worker .$h"; done
$SSH milo@192.168.1.51 'docker stop -t 60 dsv41-nfs >/dev/null' || die "stop nfs"
for h in $N; do c=$($SSH milo@192.168.1.$h 'docker ps -q | wc -l' | tr -d ' '); [ "$c" = 0 ] || die ".$h still has $c containers"; done
for h in $N; do $SSH milo@192.168.1.$h 'bash /home/milo/kbench/switch_to_580.sh --dry-run 2>&1 | tail -2' | tee -a "$L" | grep -q DRY_RUN_OK || die "switch dry-run .$h (lane stopped; restart it with docker start nfs/workers/head)"; done
for h in $N; do $SSH milo@192.168.1.$h 'bash /home/milo/kbench/switch_to_580.sh 2>&1 | grep -E "STAGE1_DONE|ABORT|module 7.0.0-1024"' | tee -a "$L" | grep -q STAGE1_DONE || die "switch .$h (DO NOT reboot .$h)"; done
for h in $N; do $SSH milo@192.168.1.$h 'bash /home/milo/kbench/finalize_stock_1024.sh 2>&1 | grep -E "holds now|first boot|FINAL_DONE|ABORT"' | tee -a "$L" | grep -q FINAL_DONE || die "finalize .$h (DO NOT reboot .$h)"; done
log "rebooting 1-4"
for h in $N; do $SSH milo@192.168.1.$h 'sudo -n systemctl reboot' 2>/dev/null; done
sleep 110
for h in $N; do
  for t in $(seq 1 40); do $SSH milo@192.168.1.$h true 2>/dev/null && break; sleep 8; done
  l=$($SSH milo@192.168.1.$h 'echo "$(uname -r) $(nvidia-smi --query-gpu=driver_version --format=csv,noheader) $(grep -c kho=off /proc/cmdline) $(grep -c 595.84 /run/cdi/nvidia.yaml)"')
  log "spark${h#5}: $l"; set -- $l
  [ "$1" = 7.0.0-1024-nvidia ] && [ "$2" = 580.178.04 ] && [ "$4" = 0 ] || die "boot gate spark${h#5}: $l"
done
log "starting production lane (nfs -> workers -> head)"
$SSH milo@192.168.1.51 'docker start dsv41-nfs >/dev/null' || die "start nfs"; sleep 10
for h in 52 53 54; do $SSH milo@192.168.1.$h 'docker start dsv41-worker >/dev/null' || die "start worker .$h"; done; sleep 10
$SSH milo@192.168.1.51 'docker start dsv41-head >/dev/null' || die "start head"
t0=$(date +%s); ok=""
for t in $(seq 1 90); do curl -s -m 5 http://192.168.1.51:8888/v1/models | grep -q '"id"' && { ok=1; break; }; sleep 10; done
[ -n "$ok" ] || { $SSH milo@192.168.1.51 'docker logs --tail 60 dsv41-head 2>&1' > "$HERE/../receipts/prod-1to4-boot-fail.log"; die "production lane not ready after 15 min"; }
log "lane READY after $(( $(date +%s) - t0 ))s"
r=$(curl -s -m 120 http://192.168.1.51:8888/v1/chat/completions -H 'Content-Type: application/json' -d '{"model":"deepseek-v4.1-flash","messages":[{"role":"user","content":"Say PONG"}],"max_tokens":8,"temperature":0,"chat_template_kwargs":{"thinking":false}}' | python3 -c "import json,sys;print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>&1)
log "chat: $r"
si=$(curl -s -m 20 http://192.168.1.51:8888/get_server_info | python3 -c "import json,sys;d=json.load(sys.stdin);print('tp',d.get('tp_size'),'max_total_tokens',d.get('max_total_num_tokens'),'ctx',d.get('context_length'))" 2>&1)
log "server_info: $si"
log "UPGRADE 1-4 DONE"
