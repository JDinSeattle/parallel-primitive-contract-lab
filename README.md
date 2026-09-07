# Parallel Primitive Contract Lab

[![CPU contracts](https://github.com/JDinSeattle/parallel-primitive-contract-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/JDinSeattle/parallel-primitive-contract-lab/actions/workflows/ci.yml)

A C++/CUDA histogram qualification project about **type contracts, independent oracles and honest regression evidence**. It reproduces a real CUB signed-byte failure, tests an existing upstream patch, and measures the cost of its dispatch change.

The known bad CCCL revision fails **20 of 38 GPU cases**; the existing patched revision passes **38 of 38**, with output guards intact. The compiled CPU oracle has **263 checks**. [Exact results, sanitizer logs and version comparisons](docs/RESULTS.md).

## Reproduce

Requires Linux, Git/curl, a C++17 compiler, CUDA toolkit/Compute Sanitizer, a real NVIDIA GPU, and uv:

```bash
bash scripts/reproduce.sh
```

The script downloads two immutable CCCL revisions, builds the same probe against each, runs CPU ASan/UBSan, GPU memcheck/racecheck, and seven shuffled benchmark rounds. Default build target is sm_89. Missing GPU or a wrong expected failure stops the run.

Minimal reproduction after setup:

```bash
build/46a37f86b650bfc90b6cd852771bd31952688097 minimal  # expected exit 2
build/a7f211c17cd15673d4bc8dbe2215c6952d9a1aef minimal  # expected exit 0
```

CPU-only: `python scripts/run.py --cpu-only` with pytest installed. Report: `python scripts/summarize.py results/<run-directory>`.

## Engineering evidence

- Independent interval-search oracle, widened arithmetic and explicit overflow handling.
- Signed/unsigned byte, int16, int32 and native-char coverage; exact edges, empty inputs, large bin counts and wide counters.
- Protected output buffers and real device execution; no mocked CUDA success.
- Bad-version failure as an acceptance condition, immutable version and binary hashes, and unsigned fast-path controls.
- Raw timing arrays, per-round medians and dispersion; correctness and sanitizer stay outside timing.

The fix is authored in existing [upstream PR #10993](https://github.com/NVIDIA/cccl/pull/10993). **This repository is independent validation, not a claim of new patch authorship or an accepted upstream contribution.** The [contract/root-cause explanation](docs/contract.md), [review packet](docs/UPSTREAM_REVIEW.md), and [interview guide](docs/INTERVIEW.md) define the scope precisely. Floating-point bins, multichannel APIs and multi-GPU portability are not qualified here.
