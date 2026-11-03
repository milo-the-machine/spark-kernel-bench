#!/bin/bash
# T5 single-Spark phase (what most owners run): llama.cpp llama-bench on gpt-oss-120b (MXFP4 GGUF), bf16 GEMM peak,
# device memory bandwidth. Run on ONE node with nothing else on the GPU.   single_node.sh <ARM> [host]
set -u
ARM=$1; H=${2:-192.168.1.55}
HERE=$(cd "$(dirname "$0")" && pwd); R=$HERE/../receipts/$ARM; mkdir -p "$R"
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"
IMG=${KB_IMG:-nvcr.io/nvidia/pytorch:25.09-py3}
log() { echo "$(date '+%F %T') $*" | tee -a "$R/single.log"; }
log "SINGLE $ARM start on $H"
$SSH milo@$H 'sync; echo 3 | sudo -n tee /proc/sys/vm/drop_caches >/dev/null; nvidia-smi --query-compute-apps=pid --format=csv,noheader | wc -l' | grep -qx 0 || { log "ABORT: GPU busy"; exit 2; }
# llama-bench: ggml-org Spark convention (fa on, ub 2048, pp2048/tg32 at depth 0/4096/16384), 3 reps each
$SSH milo@$H "docker run --rm --gpus all -v /home/milo/kbench/llama.cpp:/src -v /home/milo/models/gpt-oss-120b-GGUF:/m $IMG \
  /src/${KB_LLAMA_BUILD:-build-cu130}/bin/llama-bench -m /m/gpt-oss-120b-MXFP4.gguf \
  -fa on -ub 2048 -b 2048 -p 2048 -n 32 -d 0,4096,16384 -r 3 -lm none -o jsonl" > "$R/llama-bench.jsonl" 2> "$R/llama-bench.err"
log "llama-bench rc=$? rows=$(grep -c '^{' "$R/llama-bench.jsonl")"
$SSH milo@$H "docker run --rm --gpus all -v /home/milo/kbench:/kb $IMG python3 /kb/gemm_membw.py" > "$R/gemm_membw.jsonl" 2>&1
log "gemm/membw $(tail -2 "$R/gemm_membw.jsonl" | tr '\n' ' ')"
log "SINGLE $ARM end"
