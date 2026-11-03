#!/usr/bin/env python3
"""Hold N GiB of cudaMalloc'd memory until killed (simulates a resident model on a GB10's unified memory).
Also reports how much could actually be allocated: `hog.py --probe` allocates 1 GiB chunks until failure,
prints the total, frees, and exits (memory-headroom metric, T6)."""
import sys, time, json, os
import torch

args = sys.argv[1:]
if args and args[0] == "--probe":
    # SAFE headroom probe. Never allocate to failure on a GB10: cudaMalloc is not charged to the cgroup, so the
    # kernel OOM killer fires on the host (measured: it killed the user session) before CUDA returns an error.
    # Allocate in 1 GiB chunks up to MemAvailable - 8 GiB and report how far that got and how long it took.
    avail_gib = int(open("/proc/meminfo").read().split("MemAvailable:")[1].split()[0]) // 1048576
    limit = max(0, avail_gib - 8)
    free_b, total_b = torch.cuda.mem_get_info()
    got = []
    t = time.time()
    try:
        while len(got) < limit:
            got.append(torch.empty(1 << 30, dtype=torch.uint8, device="cuda"))
    except RuntimeError as e:
        err = str(e).splitlines()[0][:200]
    else:
        err = None
    n = len(got)
    del got
    torch.cuda.empty_cache()
    print(json.dumps({"kind": "alloc_probe", "memavail_gib": avail_gib, "limit_gib": limit, "allocated_gib": n,
                      "cuda_free_gib": round(free_b / 2**30, 1), "cuda_total_gib": round(total_b / 2**30, 1),
                      "secs": round(time.time() - t, 1), "stop_reason": err, "kernel": os.uname().release}), flush=True)
    sys.exit(0)

n = int(args[0]) if args else 100
hold = [torch.empty(1 << 30, dtype=torch.uint8, device="cuda") for _ in range(n)]
for h in hold:
    h.fill_(1)
torch.cuda.synchronize()
print(json.dumps({"kind": "hog", "held_gib": n}), flush=True)
while True:
    time.sleep(3600)
