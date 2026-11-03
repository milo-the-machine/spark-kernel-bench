## S0-6.17.0-1032-580.178.04-c1-r1 (2026-11-02T05:47:52Z)

dsv41-5way S0-6.17.0-1032-580.178.04 c1 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.05 | 104.53 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 134.19 |
| json | 104.93 |
| narrative | 61.64 |
| prose | 78.08 |
| math | 127.58 |
| reasoning | 101.65 |
| summary | 78.81 |
| format | 149.35 |
| ceiling_count | 162.7 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
