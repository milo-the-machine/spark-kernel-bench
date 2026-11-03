## S0-6.17.0-1032-580.178.04-c16-r1 (2026-11-02T05:48:46Z)

dsv41-5way S0-6.17.0-1032-580.178.04 c16 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 493.15 | 37.68 | 0.5 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 51.54 |
| json | 38.79 |
| narrative | 21.99 |
| prose | 26.92 |
| math | 45.59 |
| reasoning | 36.16 |
| summary | 27.03 |
| format | 53.39 |
| ceiling_count | 69.01 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
