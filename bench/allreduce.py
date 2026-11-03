#!/usr/bin/env python3
"""NCCL all_reduce bandwidth sweep for DGX Spark clusters (torch.distributed, no MPI needed).

Launch one process per node with torchrun, e.g.
  torchrun --nnodes 2 --node_rank R --nproc_per_node 1 --master_addr 10.0.0.5 --master_port 29555 allreduce.py

--hog-gib N  first holds N GiB of cudaMalloc'd memory on every rank (the "model is resident" condition under
             which the 7.0.0-1019 ibv_reg_mr ENOMEM regression was reported), then initialises NCCL.
Prints one JSON line per size plus a final summary line, rank 0 only. Exit 0 = ok, 3 = NCCL/RDMA failure.
"""
import argparse, json, os, sys, time, traceback

import torch
import torch.distributed as dist

ap = argparse.ArgumentParser()
ap.add_argument("--min-bytes", type=int, default=1 << 20)
ap.add_argument("--max-bytes", type=int, default=4 << 30)
ap.add_argument("--warmup", type=int, default=5)
ap.add_argument("--iters", type=int, default=20)
ap.add_argument("--hog-gib", type=int, default=0)
ap.add_argument("--label", default="")
a = ap.parse_args()

rank = int(os.environ.get("RANK", 0))
world = int(os.environ.get("WORLD_SIZE", 1))
torch.cuda.set_device(0)


def out(d):
    if rank == 0:
        print(json.dumps(d), flush=True)


hog = []
if a.hog_gib:
    for _ in range(a.hog_gib):
        hog.append(torch.empty(1 << 30, dtype=torch.uint8, device="cuda"))
    hog_ok = len(hog)
    torch.cuda.synchronize()
else:
    hog_ok = 0

meta = {"kind": "meta", "label": a.label, "world": world, "hog_gib": hog_ok,
        "torch": torch.__version__, "nccl": ".".join(map(str, torch.cuda.nccl.version())),
        "kernel": os.uname().release,
        "env": {k: v for k, v in os.environ.items() if k.startswith("NCCL_")}}
status, err, rows = "ok", None, []
try:
    dist.init_process_group("nccl", device_id=torch.device("cuda:0"))
    out(meta)
    size = a.min_bytes
    while size <= a.max_bytes:
        n = size // 4
        x = torch.ones(n, dtype=torch.float32, device="cuda")
        iters = a.iters if size < (256 << 20) else max(5, a.iters // 4)
        for _ in range(a.warmup):
            dist.all_reduce(x)
        torch.cuda.synchronize()
        dist.barrier()
        t = time.perf_counter()
        for _ in range(iters):
            dist.all_reduce(x)
        torch.cuda.synchronize()
        dt = (time.perf_counter() - t) / iters
        algbw = size / dt / 1e9
        busbw = algbw * 2 * (world - 1) / world
        # correctness: after warmup+iters reductions of ones, every element equals world**(warmup+iters)? no —
        # values grow; check a fresh reduce instead
        y = torch.ones(1024, device="cuda"); dist.all_reduce(y)
        correct = bool(torch.all(y == world).item())
        row = {"kind": "row", "bytes": size, "time_us": round(dt * 1e6, 1), "algbw_GBs": round(algbw, 3),
               "busbw_GBs": round(busbw, 3), "busbw_Gbps": round(busbw * 8, 2), "correct": correct}
        rows.append(row); out(row)
        del x
        size *= 2
except Exception as e:  # noqa: BLE001 - we want the failure text in the receipt
    status, err = "fail", f"{type(e).__name__}: {e}"
    if rank == 0:
        traceback.print_exc()
peak = max((r["busbw_GBs"] for r in rows), default=0)
out({"kind": "summary", "label": a.label, "status": status, "error": err, "sizes_done": len(rows),
     "peak_busbw_GBs": peak, "peak_busbw_Gbps": round(peak * 8, 2), "hog_gib": hog_ok, "world": world})
try:
    dist.destroy_process_group()
except Exception:
    pass
sys.exit(0 if status == "ok" else 3)
