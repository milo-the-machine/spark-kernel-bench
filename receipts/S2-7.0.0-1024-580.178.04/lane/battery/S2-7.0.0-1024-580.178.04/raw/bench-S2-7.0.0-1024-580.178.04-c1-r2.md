## S2-7.0.0-1024-580.178.04-c1-r2 (2026-11-02T19:30:40Z)

dsv41-5way S2-7.0.0-1024-580.178.04 c1 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.25 | 104.72 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 133.93 |
| json | 105.0 |
| narrative | 62.3 |
| prose | 77.94 |
| math | 127.95 |
| reasoning | 101.54 |
| summary | 79.43 |
| format | 149.64 |
| ceiling_count | 163.48 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
