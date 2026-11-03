## K0-6.17.0-1031-595.84-c16-r3 (2026-11-02T04:41:00Z)

dsv41-5way K0-6.17.0-1031-595.84 c16 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 481.48 | 36.5 | 0.485 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 50.26 |
| json | 38.45 |
| narrative | 21.79 |
| prose | 26.57 |
| math | 44.51 |
| reasoning | 35.53 |
| summary | 26.12 |
| format | 48.76 |
| ceiling_count | 68.21 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
