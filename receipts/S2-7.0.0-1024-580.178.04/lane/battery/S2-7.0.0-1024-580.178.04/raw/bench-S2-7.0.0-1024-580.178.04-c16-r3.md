## S2-7.0.0-1024-580.178.04-c16-r3 (2026-11-02T19:32:51Z)

dsv41-5way S2-7.0.0-1024-580.178.04 c16 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 484.69 | 37.01 | 0.51 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 52.58 |
| json | 39.05 |
| narrative | 22.0 |
| prose | 26.64 |
| math | 45.62 |
| reasoning | 34.92 |
| summary | 26.84 |
| format | 48.45 |
| ceiling_count | 68.77 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
