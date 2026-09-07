# Measured qualification report

Run: `verified-final-20260907`. Execution status: **passed**.

[All commands and exit codes](../results/verified-final-20260907/execution.json) · [CPU test log](../results/verified-final-20260907/cpu-tests.log) · [GPU correctness](../results/verified-final-20260907/gpu-check.json) · [Raw timing](../results/verified-final-20260907/benchmark.json)

Source digest: `bc07243394e269515b3f494f11bd75c1755e6aebe60407d02e4b22ac82338ae8`.

Hardware: RTX 4090 (sm_89), driver 595.84, native toolkit CUDA 13.2. Clocks unchanged; display GPU. Results apply to this run and workload only.

CPU: 2 tests. All command return codes are retained; missing prerequisites fail the reproduction driver.

CPU oracle: 263 additional compiled checks, ASan/UBSan clean. The known bad revision fails 20/38 GPU cases; the upstream patched revision passes 38/38 with intact guards.

| Benchmark (1M samples) | Base µs | Patched µs | Patched / base time |
|---|---:|---:|---:|
| unsigned-fast | 6.09 | 6.09 | 1.000× |
| int32-control | 7.73 | 7.73 | 1.000× |
| signed-positive | 5.94 | 7.63 | 1.284× |

Times summarize seven shuffled process-round medians; raw per-round distributions remain available. Any signed-positive slowdown is a correctness/dispatch tradeoff, not an unsigned fast-path regression. A small ratio near the run dispersion is inconclusive.

The patch belongs to existing upstream PR #10993. This is independent regression evidence, not a new or accepted upstream fix.

## Safety and reproducibility

- [gpu-memcheck log](../results/verified-final-20260907/gpu-memcheck.log): exit 0.
- [gpu-racecheck log](../results/verified-final-20260907/gpu-racecheck.log): exit 0.

The reproduction driver fails on missing GPU, failed checks, stale gates, sanitizer errors or subprocess failure. CPU CI is labeled separately. All performance comparisons retain failures and unsupported cases.
