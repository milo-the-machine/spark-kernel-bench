## K0-6.17.0-1031-595.84-c1-r1 (2026-11-02T04:38:31Z)

dsv41-5way K0-6.17.0-1031-595.84 c1 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 94.06 | 105.57 | 0.159 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 134.79 |
| json | 105.9 |
| narrative | 62.5 |
| prose | 79.83 |
| math | 128.78 |
| reasoning | 102.44 |
| summary | 80.01 |
| format | 150.29 |
| ceiling_count | 164.0 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
