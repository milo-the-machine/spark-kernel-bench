#!/bin/bash
# T7: does the ZDI-CAN-33367 mitigation (user.max_user_namespaces=0) break what a Spark owner uses?
# Runtime-only sysctl on two nodes, restored at exit. Does NOT run any exploit.   userns_test.sh <ARM>
set -u
ARM=$1; HERE=$(cd "$(dirname "$0")" && pwd); R=$HERE/../receipts/$ARM; mkdir -p "$R"; OUT=$R/userns.jsonl
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"; IMG=${KB_IMG:-nvcr.io/nvidia/pytorch:25.09-py3}
A=192.168.1.57; B=192.168.1.58
j() { echo "{\"kind\":\"userns\",\"arm\":\"$ARM\",\"node\":\"$1\",\"check\":\"$2\",\"result\":\"$3\",\"detail\":$(printf '%s' "$4" | python3 -c 'import json,sys;print(json.dumps(sys.stdin.read()[:300]))')}" | tee -a "$OUT"; }
restore() { for h in $A $B; do $SSH milo@$h "sudo -n sysctl -qw user.max_user_namespaces=\$(cat /home/milo/kbench/userns.orig 2>/dev/null || echo 511827); sysctl -n user.max_user_namespaces"; done; }
trap restore EXIT
# control: same Firefox headless screenshot with namespaces at their default, before the sysctl
for h in $A $B; do n=spark${h##*.5}; o=$($SSH milo@$h 'rm -f /tmp/ff.png; timeout 90 snap run firefox --headless --screenshot /tmp/ff.png about:blank >/dev/null 2>&1; echo rc=$? png=$(ls /tmp/ff.png 2>/dev/null | wc -l)'); j $n firefox_snap_headless_CONTROL INFO "$o"; done
for h in $A $B; do $SSH milo@$h 'sysctl -n user.max_user_namespaces > /home/milo/kbench/userns.orig; sudo -n sysctl -qw user.max_user_namespaces=0; sysctl -n user.max_user_namespaces' >/dev/null; done
for h in $A $B; do
  n=spark${h##*.5}
  o=$($SSH milo@$h 'unshare -Ur true 2>&1; echo rc=$?'); case "$o" in *rc=0*) j $n unshare_user_ns ALLOWED "$o";; *) j $n unshare_user_ns BLOCKED "$o";; esac
  o=$($SSH milo@$h "docker run --rm --gpus all $IMG python3 -c 'import torch;print(torch.cuda.is_available(), torch.cuda.get_device_name(0))' 2>&1 | tail -1"); case "$o" in True*) j $n docker_gpu_container OK "$o";; *) j $n docker_gpu_container FAIL "$o";; esac
  o=$($SSH milo@$h 'docker run --rm --security-opt seccomp=unconfined alpine:3 sh -c "unshare -U true && echo inner-userns-ok || echo inner-userns-blocked" 2>&1 | tail -1'); j $n userns_inside_container INFO "$o"
  o=$($SSH milo@$h 'systemd-run --user --wait --pipe -q true 2>&1; echo rc=$?'); j $n systemd_user_run INFO "$o"
  o=$($SSH milo@$h 'ls /snap/bin 2>/dev/null | tr "\n" " "'); j $n snaps_present INFO "$o"
  o=$($SSH milo@$h 'rm -f /tmp/ff.png; timeout 90 snap run firefox --headless --screenshot /tmp/ff.png about:blank >/dev/null 2>&1; echo rc=$? png=$(ls /tmp/ff.png 2>/dev/null | wc -l)'); j $n firefox_snap_headless INFO "$o"
done
# NCCL over RoCE between the two nodes with the sysctl in force
port=29600; D="docker run --rm --gpus all --network host --ipc host --ulimit memlock=-1 --device /dev/infiniband --cap-add IPC_LOCK -v /home/milo/kbench:/kb -e NCCL_IB_HCA=rocep1s0f0,roceP2p1s0f0 -e NCCL_IB_GID_INDEX=3 -e NCCL_SOCKET_IFNAME=enp1s0f0np0 -e GLOO_SOCKET_IFNAME=enp1s0f0np0 $IMG torchrun --nnodes 2 --nproc_per_node 1 --master_addr 10.0.0.7 --master_port $port"
$SSH milo@$B "timeout 300 $D --node_rank 1 /kb/allreduce.py --max-bytes 268435456 --label userns0" > $R/userns-nccl-r1.log 2>&1 &
o=$($SSH milo@$A "timeout 300 $D --node_rank 0 /kb/allreduce.py --max-bytes 268435456 --label userns0" 2>&1 | grep '"summary"'); wait
case "$o" in *'"ok"'*) j spark7+8 nccl_roce_2node OK "$o";; *) j spark7+8 nccl_roce_2node FAIL "$o";; esac
