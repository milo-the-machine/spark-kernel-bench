## S0-6.17.0-1032-580.178.04-c16-r2 (2026-11-02T05:49:32Z)

dsv41-5way S0-6.17.0-1032-580.178.04 c16 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 481.49 | 37.14 | 0.516 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 49.88 |
| json | 38.97 |
| narrative | 21.96 |
| prose | 26.13 |
| math | 45.07 |
| reasoning | 35.33 |
| summary | 26.83 |
| format | 52.93 |
| ceiling_count | 68.54 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
