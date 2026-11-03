## K0-6.17.0-1031-595.84-c1-r3 (2026-11-02T04:39:06Z)

dsv41-5way K0-6.17.0-1031-595.84 c1 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.66 | 105.07 | 0.16 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 135.65 |
| json | 106.14 |
| narrative | 62.09 |
| prose | 78.95 |
| math | 127.82 |
| reasoning | 101.55 |
| summary | 79.08 |
| format | 149.26 |
| ceiling_count | 161.97 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
