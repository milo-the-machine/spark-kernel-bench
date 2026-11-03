## S1-7.0.0-1019-580.178.04-c1-r3 (2026-11-02T12:23:11Z)

dsv41-5way S1-7.0.0-1019-580.178.04 c1 rep 3/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.14 | 104.5 | 0.161 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 134.04 |
| json | 105.01 |
| narrative | 61.46 |
| prose | 77.59 |
| math | 127.68 |
| reasoning | 101.88 |
| summary | 78.74 |
| format | 149.59 |
| ceiling_count | 163.03 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
