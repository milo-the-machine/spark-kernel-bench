## S2-7.0.0-1024-580.178.04-c16-r1 (2026-11-02T19:31:16Z)

dsv41-5way S2-7.0.0-1024-580.178.04 c16 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 484.15 | 36.69 | 0.472 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 49.53 |
| json | 39.03 |
| narrative | 22.07 |
| prose | 27.02 |
| math | 45.7 |
| reasoning | 36.27 |
| summary | 24.96 |
| format | 48.91 |
| ceiling_count | 69.12 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
