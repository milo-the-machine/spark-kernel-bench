#!/bin/bash
# Detached campaign runner (M4). Walks: K0 T7 -> driver switch to 580.178.04 -> S0 (6.17.0-1032) -> S1 (7.0.0-1019)
# -> S1x (1019 without kho=off, fabric+lane only) -> S2 (7.0.0-1024). Every step gated; first failure STOPS the
# campaign (no further reboots) and writes CAMPAIGN_STOPPED with the reason.  Resume: campaign.sh --from <STEP>.
#   nohup bash campaign.sh > ../receipts/campaign.out 2>&1 &
set -u
HERE=$(cd "$(dirname "$0")" && pwd); RD=$HERE/../receipts; CL=$RD/campaign.log
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"
FROM=${2:-}; [ "${1:-}" = "--from" ] || FROM=""
IDLE_MIN=${IDLE_MIN:-240}; LOADED_MIN=${LOADED_MIN:-120}
API=http://192.168.1.55:8002; MODEL=deepseek-v4.1-flash-spark-vllm
log() { echo "$(date '+%F %T %Z') $*" | tee -a "$CL"; }
stop() { log "CAMPAIGN_STOPPED: $*"; echo "STOPPED $(date -Is) $*" > "$RD/CAMPAIGN_STATE"; exit 1; }
state() { echo "$(date -Is) $*" > "$RD/CAMPAIGN_STATE"; log "STEP $*"; }
skip() { [ -n "$FROM" ] || return 1; [ "$1" = "$FROM" ] && { FROM=""; return 1; }; log "skip $1 (resuming from $FROM)"; return 0; }

lane_down() { $SSH milo@192.168.1.55 'docker stop -t 60 dsv41-karmic-kraken >/dev/null 2>&1'; for h in 56 57 58; do $SSH milo@192.168.1.$h 'docker stop -t 60 dsv41-karmic-kraken >/dev/null 2>&1'; done; }

gate_boot() { # ARM KV : every node on KV, driver 580.178.04, dri present, CDI fresh
  local arm=$1 kv=$2 bad=0
  for h in 55 56 57 58; do
    l=$($SSH milo@192.168.1.$h "echo \$(uname -r) \$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>&1|head -1|tr ' ' _) \$(ls /dev/dri/by-path/pci-000f:01:00.0-card >/dev/null 2>&1 && echo dri) \$(grep -c 595.84 /run/cdi/nvidia.yaml 2>/dev/null || echo 0)" 2>&1)
    log "gate $arm spark${h#5}: $l"
    set -- $l
    [ "${1:-}" = "$kv" ] || { [ "${1:-}" = 6.17.0-1032-nvidia ] && log "FINDING $arm spark${h#5}: came back on fallback 6.17.0-1032 (one-shot $kv did not stick: crash/reset during boot?)"; bad=1; }
    [ "${2:-}" = 580.178.04 ] && [ "${3:-}" = dri ] && [ "${4:-1}" = 0 ] || bad=1
  done
  return $bad
}

full_arm() { # ARM KV FLAG FULL(1|0)
  local arm=$1 kv=$2 flag=$3 full=$4
  state "$arm boot $kv $flag"
  bash $HERE/boot_arm.sh $kv $flag >> "$RD/boot-$arm.log" 2>&1
  gate_boot $arm $kv || { $SSH milo@192.168.1.55 'journalctl -b -1 -k --no-pager | tail -80' > "$RD/$arm-prevboot-spark5.log" 2>&1; stop "$arm boot gate failed (see boot-$arm.log)"; }
  state "$arm fabric"; bash $HERE/run_fabric.sh $arm 3 >> "$RD/$arm-run.out" 2>&1
  state "$arm lane"; KEEP_UP=1 bash $HERE/run_lane.sh $arm >> "$RD/$arm-run.out" 2>&1 || { lane_down; stop "$arm lane failed"; }
  if [ "$full" = 1 ]; then
    state "$arm loaded soak ${LOADED_MIN}m"
    python3 $HERE/load.py $API $MODEL 4 $LOADED_MIN "$RD/$arm/load.json" >> "$RD/$arm-run.out" 2>&1 &
    lp=$!; bash $HERE/soak_watch.sh $arm loaded $LOADED_MIN >> "$RD/$arm-run.out" 2>&1; wait $lp
    log "$arm loaded: $(cat $RD/$arm/soak-loaded-summary.json) load=$(python3 -c "import json;d=json.load(open('$RD/$arm/load.json'));print(d['ok'],'ok',d['err'],'err',d['tok_s_avg'],'tok/s')" 2>&1)"
  fi
  lane_down; log "$arm lane stopped (kept)"
  if [ "$full" = 1 ]; then
    state "$arm single-node"; bash $HERE/single_node.sh $arm 192.168.1.55 >> "$RD/$arm-run.out" 2>&1
    [ "$arm" = S2-7.0.0-1024-580.178.04 ] && { state "$arm userns"; bash $HERE/userns_test.sh $arm >> "$RD/$arm-run.out" 2>&1; }
    state "$arm idle soak ${IDLE_MIN}m (headless, nothing running)"
    bash $HERE/soak_watch.sh $arm idle $IDLE_MIN >> "$RD/$arm-run.out" 2>&1
    log "$arm idle: $(cat $RD/$arm/soak-idle-summary.json)"
  fi
  python3 $HERE/aggregate.py "$RD" > "$RD/TABLE.md" 2>&1
  log "ARM $arm DONE"
}

log "CAMPAIGN start (idle ${IDLE_MIN}m, loaded ${LOADED_MIN}m)"
if ! skip K0C13; then
  state "K0c13: llama.cpp cu13.0 build + fabric/single on NGC 25.09 (same container as the S arms)"
  $SSH milo@192.168.1.55 'bash /home/milo/kbench/build_llama.sh' > "$RD/build-llama-cu130.log" 2>&1
  grep -q BUILD_RC=0 "$RD/build-llama-cu130.log" || stop "llama.cpp cu130 build failed"
  for h in 56 57 58; do $SSH milo@192.168.1.55 "rsync -a /home/milo/kbench/llama.cpp/ 10.0.0.${h#5}:/home/milo/kbench/llama.cpp/" ; done
  bash $HERE/run_fabric.sh K0c13-6.17.0-1031-595.84 3 >> "$RD/K0c13-run.out" 2>&1
  bash $HERE/single_node.sh K0c13-6.17.0-1031-595.84 192.168.1.55 >> "$RD/K0c13-run.out" 2>&1
  rm -f "$RD/K0-6.17.0-1031-595.84/llama-bench.jsonl" "$RD/K0-6.17.0-1031-595.84/gemm_membw.jsonl"
  KB_IMG=nvcr.io/nvidia/pytorch:26.07-py3 KB_LLAMA_BUILD=build bash $HERE/single_node.sh K0-6.17.0-1031-595.84 192.168.1.55 >> "$RD/K0-rest.out" 2>&1
  log "K0c13 done: $(tail -1 $RD/K0c13-6.17.0-1031-595.84/single.log)"
fi
if ! skip K0T7; then state "K0 userns"; bash $HERE/userns_test.sh K0-6.17.0-1031-595.84 >> "$RD/K0-userns.out" 2>&1; fi
if ! skip SWITCH; then
  state "driver switch dry-run"
  for h in 55 56 57 58; do $SSH milo@192.168.1.$h 'bash /home/milo/kbench/switch_to_580.sh --dry-run' >> "$RD/switch580.log" 2>&1 || stop "switch dry-run failed on .$h"; done
  state "driver switch 595.84 -> 580.178.04"
  for h in 55 56 57 58; do $SSH milo@192.168.1.$h 'bash /home/milo/kbench/switch_to_580.sh' >> "$RD/switch580.log" 2>&1 || stop "switch failed on .$h (no reboot issued; node keeps running 595.84 until reboot)"; done
  log "switch done: $(grep -c STAGE1_DONE $RD/switch580.log)/4 STAGE1_DONE"
fi
skip S0  || full_arm S0-6.17.0-1032-580.178.04 6.17.0-1032-nvidia "" 1
skip S1  || full_arm S1-7.0.0-1019-580.178.04 7.0.0-1019-nvidia "" 1
skip S1x || full_arm S1x-7.0.0-1019-nokho-580.178.04 7.0.0-1019-nvidia --no-kho-off 0
skip S2  || full_arm S2-7.0.0-1024-580.178.04 7.0.0-1024-nvidia "" 1
state "CAMPAIGN_DONE (nodes on 7.0.0-1024 this boot; GRUB default 6.17.0-1032; lane stopped+kept; guest lane still shelved)"
