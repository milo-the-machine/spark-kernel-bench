## K0-6.17.0-1031-595.84-c1-r2 (2026-11-02T04:38:48Z)

dsv41-5way K0-6.17.0-1031-595.84 c1 rep 2/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 94.34 | 105.82 | 0.159 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 135.9 |
| json | 105.58 |
| narrative | 63.02 |
| prose | 79.43 |
| math | 129.03 |
| reasoning | 102.81 |
| summary | 79.91 |
| format | 150.88 |
| ceiling_count | 163.46 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
