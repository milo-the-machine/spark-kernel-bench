## S2-7.0.0-1024-580.178.04-c16-r2 (2026-11-02T19:32:03Z)

dsv41-5way S2-7.0.0-1024-580.178.04 c16 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 484.44 | 36.92 | 0.515 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 51.81 |
| json | 38.47 |
| narrative | 21.49 |
| prose | 26.66 |
| math | 45.61 |
| reasoning | 36.25 |
| summary | 26.96 |
| format | 48.08 |
| ceiling_count | 64.48 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
