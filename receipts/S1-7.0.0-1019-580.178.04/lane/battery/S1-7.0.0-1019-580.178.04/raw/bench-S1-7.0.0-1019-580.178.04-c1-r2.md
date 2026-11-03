## S1-7.0.0-1019-580.178.04-c1-r2 (2026-11-02T12:22:53Z)

dsv41-5way S1-7.0.0-1019-580.178.04 c1 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 92.97 | 104.42 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 134.14 |
| json | 104.53 |
| narrative | 61.51 |
| prose | 78.57 |
| math | 127.68 |
| reasoning | 100.96 |
| summary | 78.76 |
| format | 149.24 |
| ceiling_count | 162.93 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
