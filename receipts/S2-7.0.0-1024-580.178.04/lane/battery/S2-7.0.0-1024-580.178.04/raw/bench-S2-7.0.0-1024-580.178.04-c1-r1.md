## S2-7.0.0-1024-580.178.04-c1-r1 (2026-11-02T19:30:22Z)

dsv41-5way S2-7.0.0-1024-580.178.04 c1 rep 1/3

Prompt set `v1` (identical across boots), temperature 0, thinking off. Tokens from the server's usage block; TTFT = first token delta.

### Throughput by concurrency (8 categories; the counting ceiling is excluded)

| C | aggregate tok/s | per-stream tok/s | mean TTFT (s) |
|---|---|---|---|
| C1 | 93.07 | 104.51 | 0.162 |

### Per-stream tok/s by category

| category | C1 |
|---|---|
| coding | 134.4 |
| json | 105.1 |
| narrative | 61.66 |
| prose | 78.17 |
| math | 127.97 |
| reasoning | 101.19 |
| summary | 78.8 |
| format | 148.78 |
| ceiling_count | 163.9 |

### Cold prefill (unique prefix)

| target | prompt tokens | TTFT (s) | prefill tok/s |
|---|---|---|---|
