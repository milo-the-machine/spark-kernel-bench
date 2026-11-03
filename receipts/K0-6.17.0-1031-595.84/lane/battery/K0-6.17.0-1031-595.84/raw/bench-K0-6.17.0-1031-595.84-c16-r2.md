## K0-6.17.0-1031-595.84-c16-r2 (2026-11-02T04:40:12Z)

dsv41-5way K0-6.17.0-1031-595.84 c16 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 480.63 | 36.66 | 0.497 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 49.41 |
| json | 38.4 |
| narrative | 21.71 |
| prose | 26.53 |
| math | 44.97 |
| reasoning | 35.97 |
| summary | 26.82 |
| format | 49.44 |
| ceiling_count | 65.37 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
