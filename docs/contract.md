# Histogram type and boundary contract

Only single-channel integer `HistogramEven` and `HistogramRange` are qualified. Levels are strictly increasing int32 values. Even tests use equally spaced levels. Each interval is `[level[i], level[i+1])`; values outside the outer interval are excluded. The sum of counters must equal the number of in-range samples. Empty input produces zero counters, not an unwritten buffer.

| Dimension | Qualified coverage |
|---|---|
| Sample types | int8, uint8, int16, int32, native char with recorded signedness |
| Counters | int32 and CUDA-supported unsigned long long |
| Boundaries | Negative values; exact lower/upper edges; 127/128/129/255/256/257 bins; full int16 domain |
| Safety | Independent pre/post output canaries, memcheck and racecheck |
| Overflow | CPU oracle raises; GPU inputs are prebounded to fit counters. No claim that CUB checks overflow. |
| Excluded | MultiHistogram, 2D row strides, floating-point bins, cross-architecture behavior |

The independent CPU oracle compares values against sorted intervals using widened arithmetic. It does not use CUB's template dispatch or privatized-bin mapping. Its small-counter overflow test is feasible without allocating billions of samples.

Signed int64 (`long` on this host) failed to compile with the tested native atomic overloads. The original compiler diagnostic is preserved under exploratory results. The explicit wide-counter contract uses `unsigned long long`, not an assumption that equal bit width implies the same C++ type contract.

## Reproduced upstream issue, not new patch authorship

[CCCL #10977](https://github.com/NVIDIA/cccl/issues/10977) already has [PR #10993](https://github.com/NVIDIA/cccl/pull/10993). This project independently tests its base `46a37f8` and head `a7f211c`. The upstream patch is credited to its author. No duplicate fix or upstream submission is claimed.

The bad byte dispatch lets negative signed samples become invalid privatized bins. Separately, casting privatized bin indices through a narrow sample type can lose bins even when samples themselves are valid. The existing patch limits the byte fast path to unsigned types and retains the bin-index width through decoding. Read both changes: fixing only the negative-sample path does not prove high-bin-count correctness.

The minimal four-sample reproduction uses `[-60,-1,10,63]` and four equal-width bins over `[-60,64)`. `build/<revision> minimal` returns 2 for the bad revision, 0 for the fixed revision, and prints observed/expected counts.

## Regression performance

Benchmark three valid one-million-sample cases: unsigned-byte fast path, int32 control, and positive signed-byte samples. The defective negative-value benchmark is deliberately not treated as a valid performance baseline. Each binary verifies its output before the timed region; seven process rounds alternate the two versions in a recorded randomized order. Events cover 20 invocations per sample, 31 samples per case. Report every round and dispersion, and keep performance regressions even when the patch fixes correctness.

The standalone reproducer and tests are reviewable evidence that could support an upstream discussion. They are not an accepted upstream contribution, and the project's single-device results do not replace maintainer CI.
