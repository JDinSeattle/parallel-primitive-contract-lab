# Parallel Primitive Contract Lab

A signed-byte histogram regression lab using an independent interval-search oracle, pinned bad and upstream-fixed CCCL revisions, output guards, and overflow-aware counting.

## Confirmed qualification results

These are the user-confirmed results from a separate cloud test run, recorded in the experience bank. The device, workload, timing round, and counting boundaries below remain part of each result. They are distinct from the CPU checks performed in this checkout; cloud-hosted testing does not imply production deployment.

- Reproduced the known signed-byte histogram defect on a pinned bad CCCL revision — 20 failures across a 38-case GPU matrix (20 cross-sign-boundary scenarios plus 18 controls) — while the existing upstream patched revision passed all 38 cases against the same independent interval-search oracle; the patch is upstream work, not an authored or accepted contribution of mine.

- Built the CPU oracle from the interval definition itself rather than another CUB call: byte inputs are widened to int64 before bucket comparison, buckets are half-open [left,right) with the rightmost edge excluded, and 263 ASan/UBSan checks cover the reference while 18 pytest include the shared 16 process/file cases.

- Verified the minimal boundary drill — input [-128,-1,0,127] with bucket boundaries [-128,-64,0,64,128] expecting [1,1,1,1] — and kept the signed-byte overflow explanation a local demonstration mutation (sample−lower stored in int8 overflows past 127; the reference always stays int64), not a claim about the upstream source root cause.

- Gated counting on overflow: output is uint32, accumulation happens in 64-bit and is rejected before UINT32_MAX, guards sit on both output ends, and every run also checks that all buckets sum to the number of in-range samples so a wrong-but-conserving bucketization cannot pass.

- Rejected 4 counterexample fixtures (negative count, duplicate bucket, missed tail element, counter overflow) and measured the cost of correctness: on the signed-positive subset the patched version took 8.8 μs against the old 8.0 μs (10% slower), with 20 warmups and 31 paired randomized-order event timings per version and the sanitizer run separately.

- Scoped the qualification to single-GPU, single-channel integer histograms on an RTX 4090 with CUDA 13.2 and C++17 (Python 3.13, Compute Sanitizer; CPU Clang 18.1.8 ASan/UBSan); floating-point, multichannel and multi-GPU merging are not in the contract.

## Implementation and reproduction

| Contract | Implementation |
|---|---|
| Widened independent interval oracle | [include/histogram_oracle.hpp](include/histogram_oracle.hpp) |
| Native histogram harness | [src](src) |
| Sanitized CPU boundary drill | [tests/oracle_test.cpp](tests/oracle_test.cpp) |
| Isolated qualification ownership | [execution.py](execution.py) |

Run each experiment into a fresh output directory to preserve earlier evidence.

```bash
python3 -m pip install pytest
python3 scripts/run.py --cpu-only --output results/my-cpu-run
# Requires the pinned CCCL revisions, CUDA and one GPU:
python3 scripts/run.py --output results/my-gpu-run
```

Regression entry points: [tests/oracle_test.cpp](tests/oracle_test.cpp), [tests/test_execution.py](tests/test_execution.py), [tests/test_evidence.py](tests/test_evidence.py).

## Scope and evidence

The source patch is upstream work. The additional local minimal-boundary regression increases the CPU oracle count separately; it does not rewrite the confirmed external 263-check report.

- The bad revision fails 20 of 38 GPU cases and the patched revision passes 38/38 on the same matrix (20 cross-sign-boundary scenarios plus 18 controls); no submission or acceptance of the upstream patch is claimed.

- 263 is the ASan/UBSan CPU reference-check count, and the 18 pytest include the shared 16 process/file cases — they must not be described as 263 pytest tests.

- The local int8 overflow mutation demonstrates the signed-byte widening mechanism but is not the upstream source root cause.

- Signed-positive dispatch can be slower: the patched version measured 8.8 μs against 8.0 μs on that subset (10%), so this is not a universal performance win.

- Single GPU, single-channel integer histograms only; NaN intervals, multichannel layouts and cross-GPU merging are outside the contract.

- Bucket-sum equality alone is not correctness; exact per-bucket comparison plus the output guards are required.

- Local RTX 4090 / CUDA 13.2 lab; the frozen bad and patched CCCL archives are bound to binary digests.

The [previous README](README.historical.md) preserves earlier setup details, design discussion, and historical measurements. Its older counts, splits, versions, and timing cohorts must not be mixed with the confirmed round above. [Result provenance](docs/experience-bank-results.json) retains the confirmed bullet text; [checkout validation](docs/checkout-validation.md) records what was actually rerun here.
