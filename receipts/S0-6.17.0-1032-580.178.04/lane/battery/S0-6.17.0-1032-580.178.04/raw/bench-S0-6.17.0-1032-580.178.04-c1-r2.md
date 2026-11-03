## S0-6.17.0-1032-580.178.04-c1-r2 (2026-11-02T05:48:10Z)

dsv41-5way S0-6.17.0-1032-580.178.04 c1 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.02 | 104.42 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 133.61 |
| json | 104.68 |
| narrative | 61.59 |
| prose | 78.52 |
| math | 127.14 |
| reasoning | 101.44 |
| summary | 78.99 |
| format | 149.43 |
| ceiling_count | 163.11 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
