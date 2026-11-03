#!/usr/bin/env python3
"""bf16 GEMM peak (60 s, best of) and device-memory copy bandwidth on one GB10. Prints JSON lines."""
import json, os, time
import torch

n = 8192
a = torch.randn(n, n, device="cuda", dtype=torch.bfloat16); b = torch.randn(n, n, device="cuda", dtype=torch.bfloat16)
for _ in range(5): a @ b
torch.cuda.synchronize()
best = 0.0; samples = []; t_end = time.time() + 60
while time.time() < t_end:
    t = time.time()
    for _ in range(10): c = a @ b
    torch.cuda.synchronize(); dt = time.time() - t
    tf = 10 * 2 * n ** 3 / dt / 1e12; samples.append(tf); best = max(best, tf)
samples.sort()
print(json.dumps({"kind": "gemm_bf16", "n": n, "peak_tflops": round(best, 2), "median_tflops": round(samples[len(samples) // 2], 2),
                  "kernel": os.uname().release}), flush=True)
del a, b
# device-to-device copy bandwidth: 4 GiB buffer, read+write counted
x = torch.empty(4 << 30, dtype=torch.uint8, device="cuda"); y = torch.empty_like(x)
for _ in range(3): y.copy_(x)
torch.cuda.synchronize()
bws = []
for _ in range(20):
    t = time.perf_counter(); y.copy_(x); torch.cuda.synchronize(); dt = time.perf_counter() - t
    bws.append(2 * x.numel() / dt / 1e9)
bws.sort()
print(json.dumps({"kind": "membw_copy", "bytes": x.numel(), "best_GBs": round(bws[-1], 1), "median_GBs": round(bws[len(bws) // 2], 1),
                  "kernel": os.uname().release}), flush=True)
