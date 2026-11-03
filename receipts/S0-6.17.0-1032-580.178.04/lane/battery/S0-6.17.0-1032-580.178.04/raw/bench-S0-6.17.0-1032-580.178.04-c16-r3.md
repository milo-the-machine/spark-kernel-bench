## S0-6.17.0-1032-580.178.04-c16-r3 (2026-11-02T05:50:20Z)

dsv41-5way S0-6.17.0-1032-580.178.04 c16 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 479.01 | 36.64 | 0.505 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 47.75 |
| json | 36.62 |
| narrative | 21.97 |
| prose | 26.55 |
| math | 45.57 |
| reasoning | 36.14 |
| summary | 26.95 |
| format | 51.55 |
| ceiling_count | 69.03 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
