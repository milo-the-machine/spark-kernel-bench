## K0-6.17.0-1031-595.84-c16-r1 (2026-11-02T04:39:24Z)

dsv41-5way K0-6.17.0-1031-595.84 c16 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C16 | 480.6 | 36.8 | 0.507 |

### Per-stream tok/s by category

| category | C16 |
|---|---|
| coding | 49.49 |
| json | 38.44 |
| narrative | 21.3 |
| prose | 26.76 |
| math | 44.72 |
| reasoning | 35.59 |
| summary | 26.53 |
| format | 51.59 |
| ceiling_count | 65.15 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
