## S1-7.0.0-1019-580.178.04-c16-r1 (2026-11-02T12:23:29Z)

dsv41-5way S1-7.0.0-1019-580.178.04 c16 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 474.57 | 36.31 | 0.49 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 50.16 |
| json | 38.68 |
| narrative | 22.08 |
| prose | 26.93 |
| math | 41.09 |
| reasoning | 36.32 |
| summary | 25.5 |
| format | 49.74 |
| ceiling_count | 66.08 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
