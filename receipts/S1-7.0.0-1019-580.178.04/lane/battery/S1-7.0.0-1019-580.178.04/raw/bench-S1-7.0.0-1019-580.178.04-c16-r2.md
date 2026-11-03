## S1-7.0.0-1019-580.178.04-c16-r2 (2026-11-02T12:24:17Z)

dsv41-5way S1-7.0.0-1019-580.178.04 c16 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 480.47 | 36.67 | 0.508 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 52.67 |
| json | 39.01 |
| narrative | 21.44 |
| prose | 26.89 |
| math | 41.95 |
| reasoning | 36.31 |
| summary | 26.96 |
| format | 48.14 |
| ceiling_count | 68.59 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
