#!/bin/bash
# T4: boot the kept Lane C (vLLM DSV4.1 TP4) on Sparks 5-8, run the DSV4.1 battery subset + teacher-forced numerics,
# then stop-and-keep the lane.   run_lane.sh <ARM>
set -u
ARM=$1
HERE=$(cd "$(dirname "$0")" && pwd); R=$HERE/../receipts/$ARM; mkdir -p "$R/lane"
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"
BAT=/Users/jamesmeadlock/hermes/work/dsv41-5way-2026-10-26/battery.py
NONINF=/Users/jamesmeadlock/hermes/spark-recipe-r4/research/noninferiority.py
BASE8=/Users/jamesmeadlock/hermes/spark-recipe-r5/noninf/baseline-8gib.json
K0NI=$HERE/../receipts/K0-6.17.0-1031-595.84/lane/noninf-candidate.json
API=http://192.168.1.55:8002; MODEL=deepseek-v4.1-flash-spark-vllm
log() { echo "$(date '+%F %T') $*" | tee -a "$R/lane/lane.log"; }

log "LANE $ARM start"
for h in 55 56 57 58; do
  $SSH milo@192.168.1.$h 'sha256sum /home/milo/models/DeepSeek-V4.1-Flash-1017/model-00010-of-00048.safetensors | cut -c1-12; docker rm -f kb-hog >/dev/null 2>&1; sync; echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null; echo 1 | sudo -n tee /proc/sys/vm/compact_memory >/dev/null; awk "/MemAvailable/{print int(\$2/1048576)\" GiB avail\"}" /proc/meminfo' | tr '\n' ' ' | sed "s/^/spark${h#5} /" | tee -a "$R/lane/lane.log"; echo | tee -a "$R/lane/lane.log"
done
grep -q 835e9a8b0a28 "$R/lane/lane.log" || { log "ABORT: base checkpoint not at model path"; exit 2; }
t0=$(date +%s)
for h in 58 57 56 55; do $SSH milo@192.168.1.$h 'docker start dsv41-karmic-kraken >/dev/null' || { log "ABORT start failed .$h"; exit 1; }; sleep 8; done
ready=""
for i in $(seq 1 90); do
  if curl -s -m 5 $API/v1/models | grep -q '"id"'; then ready=$(( $(date +%s) - t0 )); break; fi; sleep 10
done
[ -n "$ready" ] || { log "FAIL: lane not ready after 15 min"; $SSH milo@192.168.1.55 'docker logs --tail 40 dsv41-karmic-kraken 2>&1' > "$R/lane/boot-fail.log"; exit 1; }
log "READY after ${ready}s"
$SSH milo@192.168.1.55 'docker logs dsv41-karmic-kraken 2>&1' > "$R/lane/boot.log"
echo "{\"kind\":\"lane_ready\",\"arm\":\"$ARM\",\"ready_s\":$ready,\"kv_line\":\"$(grep 'GPU KV cache size' "$R/lane/boot.log" | tail -1 | sed 's/"//g' | cut -c1-200)\"}" > "$R/lane/ready.json"

python3 $BAT --lane "$ARM" --api-root $API --model $MODEL --engine vllm --phases smoke,bootfacts,c1,c16,prefill,mixed_warm \
  --prefill-lens 32768,131072 --reps 3 --out "$R/lane/battery" --boot-log "$R/lane/boot.log" >> "$R/lane/battery.out" 2>&1
log "battery rc=$? $(tail -1 "$R/lane/battery.out")"

python3 $NONINF collect --url $API --role candidate --model $MODEL --ids-from $BASE8 --out "$R/lane/noninf-candidate.json" >> "$R/lane/noninf.out" 2>&1
python3 $NONINF compare $BASE8 "$R/lane/noninf-candidate.json" --out "$R/lane/noninf-vs-base8.json" >> "$R/lane/noninf.out" 2>&1
[ -f "$K0NI" ] && [ "$R/lane/noninf-candidate.json" != "$K0NI" ] && python3 $NONINF compare "$K0NI" "$R/lane/noninf-candidate.json" --out "$R/lane/noninf-vs-K0.json" >> "$R/lane/noninf.out" 2>&1
log "noninf $(tail -3 "$R/lane/noninf.out" | tr '\n' ' ')"

[ "${KEEP_UP:-0}" = 1 ] && { log "LANE $ARM end (left UP for loaded soak)"; exit 0; }
$SSH milo@192.168.1.55 'docker stop -t 60 dsv41-karmic-kraken >/dev/null'
for h in 56 57 58; do $SSH milo@192.168.1.$h 'docker stop -t 60 dsv41-karmic-kraken >/dev/null'; done
log "LANE $ARM end (stopped, kept)"
