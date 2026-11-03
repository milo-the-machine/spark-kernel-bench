## S1-7.0.0-1019-580.178.04-c16-r3 (2026-11-02T12:25:04Z)

dsv41-5way S1-7.0.0-1019-580.178.04 c16 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 477.94 | 36.47 | 0.508 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 48.17 |
| json | 37.28 |
| narrative | 21.91 |
| prose | 26.99 |
| math | 45.69 |
| reasoning | 36.24 |
| summary | 27.11 |
| format | 48.35 |
| ceiling_count | 65.65 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
