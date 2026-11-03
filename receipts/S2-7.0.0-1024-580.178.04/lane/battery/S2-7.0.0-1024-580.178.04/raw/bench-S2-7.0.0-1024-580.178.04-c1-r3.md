## S2-7.0.0-1024-580.178.04-c1-r3 (2026-11-02T19:30:58Z)

dsv41-5way S2-7.0.0-1024-580.178.04 c1 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.16 | 104.69 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 134.25 |
| json | 105.0 |
| narrative | 61.43 |
| prose | 78.12 |
| math | 127.94 |
| reasoning | 101.47 |
| summary | 78.84 |
| format | 150.44 |
| ceiling_count | 164.04 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
