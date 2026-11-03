#!/bin/bash
# T2: perftest RDMA between two Sparks, per rail. Run from a controller that can ssh to both.
#   rdma_pair.sh <server_ip_mgmt> <client_ip_mgmt> <server_fabric_ip_rail0> <server_fabric_ip_rail1> <label>
# Prints JSON lines. GID index 3 = RoCE v2 IPv4 on DGX Spark CX-7.
set -u
S=$1; C=$2; F0=$3; F1=$4; L=${5:-}
SSH="ssh -o BatchMode=yes -o ConnectTimeout=10"
run() { # dev fabric_ip test extra
  local dev=$1 fip=$2 t=$3 extra=$4 port=$((18515 + RANDOM % 1000))
  $SSH milo@$S "pkill -x $t 2>/dev/null; timeout 60 $t -d $dev -x 3 -p $port $extra >/dev/null 2>&1 &" ; sleep 2
  local o; o=$($SSH milo@$C "timeout 50 $t -d $dev -x 3 -p $port $extra $fip 2>&1")
  local rc=$?
  local line; line=$(echo "$o" | awk '/^ *[0-9]+ +[0-9]+/{l=$0} END{print l}')
  python3 - "$L" "$dev" "$t" "$rc" "$line" "$(echo "$o" | grep -iE 'fail|error|cannot|unable' | head -3 | tr '\n' '|')" <<'P'
import json,sys
lab,dev,t,rc,line,err=sys.argv[1:]
f=line.split()
d={"kind":"rdma","label":lab,"dev":dev,"test":t,"rc":int(rc),"raw":line,"err":err or None}
try:
    if t in("ib_write_bw","ib_read_bw"): d["bw_avg_gbps"]=float(f[3])
    else: d["lat_typ_us"]=float(f[4]); d["lat_avg_us"]=float(f[5]); d["lat_p99_us"]=float(f[7]) if len(f)>7 else None
except Exception: pass
print(json.dumps(d))
P
}
for pair in "rocep1s0f0 $F0" "roceP2p1s0f0 $F1"; do
  set -- $pair
  run $1 $2 ib_write_bw "-s 1048576 -D 10 -q 4 --report_gbits -F"
  run $1 $2 ib_read_bw  "-s 1048576 -D 10 -q 4 --report_gbits -F"
  run $1 $2 ib_write_lat "-s 8 -n 20000 -F"
done
