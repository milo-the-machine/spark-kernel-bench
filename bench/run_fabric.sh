#!/bin/bash
# Fabric + node phases for one arm (T0 facts, T6 alloc probe, T2 RDMA, T3 NCCL), driven from the controller.
#   run_fabric.sh <ARM> [reps]
# Receipts: receipts/<ARM>/{facts-sparkN.json, alloc-sparkN.json, rdma-*.jsonl, nccl-*.jsonl, fabric.log}
set -u
ARM=$1; REPS=${2:-3}
HERE=$(cd "$(dirname "$0")" && pwd); R=$HERE/../receipts/$ARM; mkdir -p "$R"
IMG=${KB_IMG:-nvcr.io/nvidia/pytorch:25.09-py3}
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"
declare -a MG=(192.168.1.55 192.168.1.56 192.168.1.57 192.168.1.58)
log() { echo "$(date '+%F %T') $*" | tee -a "$R/fabric.log"; }
# community-minimal NCCL env: both rails, RoCE v2 GID 3, no tuning knobs
NENV="-e NCCL_IB_HCA=rocep1s0f0,roceP2p1s0f0 -e NCCL_IB_GID_INDEX=3 -e NCCL_SOCKET_IFNAME=enp1s0f0np0 -e GLOO_SOCKET_IFNAME=enp1s0f0np0 -e NCCL_IB_DISABLE=0 -e NCCL_DEBUG=WARN"
DOCK="docker run --rm --gpus all --network host --ipc host --ulimit memlock=-1 --ulimit stack=67108864 --device /dev/infiniband --cap-add IPC_LOCK -v /home/milo/kbench:/kb $NENV $IMG"

log "ARM $ARM start reps=$REPS"
# ---- T0 facts + T6 alloc probe
for h in "${MG[@]}"; do
  n=spark${h##*.5}
  $SSH milo@$h 'bash /home/milo/kbench/node_facts.sh' > "$R/facts-$n.json" 2>&1
  $SSH milo@$h "$DOCK python3 /kb/hog.py --probe 2>/dev/null | tail -1" > "$R/alloc-$n.json" 2>&1
  log "facts $n $(python3 -c "import json;d=json.load(open('$R/facts-$n.json'));print(d['kernel'],d['driver'],'xid',d['xid_this_boot'])" 2>&1) alloc $(cat "$R/alloc-$n.json")"
done

hog_on()  { for h in "$@"; do $SSH milo@$h "docker rm -f kb-hog >/dev/null 2>&1; docker run -d --name kb-hog --gpus all -v /home/milo/kbench:/kb $IMG python3 /kb/hog.py ${HOG_GIB:-100} >/dev/null"; done
            for h in "$@"; do for i in $(seq 1 60); do $SSH milo@$h 'docker logs kb-hog 2>&1 | grep -q held_gib' && break; sleep 3; done; done; }
hog_off() { for h in "$@"; do $SSH milo@$h 'docker rm -f kb-hog >/dev/null 2>&1'; done; }

# ---- T2 RDMA: pairs 5<-6 and 7<-8, with and without a 100 GiB resident allocation
for hog in 0 100; do
  [ $hog -gt 0 ] && hog_on "${MG[@]}"
  for rep in $(seq 1 $REPS); do
    bash "$HERE/rdma_pair.sh" 192.168.1.55 192.168.1.56 10.0.0.5 10.0.1.5 "$ARM hog$hog rep$rep 5-6" >> "$R/rdma.jsonl" 2>&1
    bash "$HERE/rdma_pair.sh" 192.168.1.57 192.168.1.58 10.0.0.7 10.0.1.7 "$ARM hog$hog rep$rep 7-8" >> "$R/rdma.jsonl" 2>&1
  done
  [ $hog -gt 0 ] && hog_off "${MG[@]}"
  log "rdma hog$hog done"
done

# ---- T3 NCCL all_reduce: 2-node (5,6) and 4-node, hog 0 / 100 (hog held inside the bench process)
nccl() { # nnodes hog rep
  local nn=$1 hog=$2 rep=$3 port=$((29500 + RANDOM % 400)) i=0 pids=()
  local tag="n${nn}-hog${hog}-rep${rep}"
  for h in "${MG[@]:0:$nn}"; do
    $SSH milo@$h "timeout 900 $DOCK torchrun --nnodes $nn --node_rank $i --nproc_per_node 1 --master_addr 10.0.0.5 --master_port $port /kb/allreduce.py --hog-gib $hog --label '$ARM $tag'" > "$R/nccl-$tag-r$i.log" 2>&1 &
    pids+=($!); i=$((i+1)); sleep 1
  done
  local rc=0; for p in "${pids[@]}"; do wait $p || rc=$?; done
  grep -h '^{' "$R/nccl-$tag-r0.log" >> "$R/nccl.jsonl"
  local s; s=$(grep -h '"summary"' "$R/nccl-$tag-r0.log" | tail -1)
  log "nccl $tag rc=$rc $s $(grep -hoiE 'ibv_reg_mr[^ ]*.{0,80}|Cannot allocate memory' "$R"/nccl-$tag-r*.log | sort | uniq -c | head -3 | tr '\n' ' ')"
}
for rep in $(seq 1 $REPS); do
  for nn in 2 4; do for hog in 0 100; do nccl $nn $hog $rep; done; done
done
log "ARM $ARM fabric end"
