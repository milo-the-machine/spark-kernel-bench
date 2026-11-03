## S1-7.0.0-1019-580.178.04-c1-r1 (2026-11-02T12:22:35Z)

dsv41-5way S1-7.0.0-1019-580.178.04 c1 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.05 | 104.44 | 0.161 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 133.54 |
| json | 105.01 |
| narrative | 61.59 |
| prose | 77.88 |
| math | 127.85 |
| reasoning | 101.9 |
| summary | 78.5 |
| format | 149.24 |
| ceiling_count | 163.08 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
