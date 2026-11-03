## S0-6.17.0-1032-580.178.04-c1-r3 (2026-11-02T05:48:28Z)

dsv41-5way S0-6.17.0-1032-580.178.04 c1 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 92.96 | 104.36 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 133.95 |
| json | 104.41 |
| narrative | 61.39 |
| prose | 77.97 |
| math | 127.24 |
| reasoning | 101.95 |
| summary | 78.74 |
| format | 149.22 |
| ceiling_count | 163.03 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
