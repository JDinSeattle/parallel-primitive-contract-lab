# Runner refresh verification — 2026-09-07

**Final execution passed on local physical RTX 4090.** Python: 18 passed,
0 failed, 0 skipped; GPU corpus: 38 records. C++ oracle: 263 checks; bad revision fails 20/38, existing patched revision passes 38/38.
The 16 new runner scenarios execute real CPU processes and filesystem failures.
They do not use simulated CUDA success.

[Structured verification and artifact hashes](../results/runner-refresh-20260907/verification.json) ·
[All commands and exit codes](../results/runner-refresh-20260907/execution.json) ·
[CPU log](../results/runner-refresh-20260907/cpu-tests.log) ·
[GPU results](../results/runner-refresh-20260907/gpu-check.json) ·
[Raw timing](../results/runner-refresh-20260907/benchmark.json)

Source digest: `e74df2652d33e624753d7817abb7f288c9ac5c06b8c07866d04cb86b1431701c`. Code remains local/uncommitted.

All configured memory-safety/profile stages in the execution receipt returned
zero; CPU-only validation is distinguished from device validation. The physical
GPU is sm_89, driver 595.84, native CUDA 13.2. Python runtime and packages are
recorded, including the separately pinned CuTe environment for A.

The pre-change timeout experiment retained in
[timeout-baseline.json](../results/runner-refresh-20260907/timeout-baseline.json)
uses the old subprocess boundary and proves a grandchild can continue after
the direct child is killed. Tests now reject that outcome, including ignored
TERM, premature wrapper success and SIGINT/SIGTERM cancellation.

No speedup is attributed to the runner change. Timed code, shapes, warmup and
sampling are unchanged. This display GPU uses unlocked clocks and can have
noncooperating graphics activity; process serialization is not exclusive GPU
hardware ownership. Earlier attempts and reasons are retained when present.
Full Nsight binary traces remain in `/tmp/kernels-refresh-20260907/B-gpu`; portable CSV summaries are
retained here. Existing [historical results](RESULTS.md) keep their original run.

Remaining boundaries: no supervisor-SIGKILL or host-crash containment, cgroup,
cloud deployment, production traffic or cross-architecture validation. No new
hosted CI run or accepted upstream PR is claimed.
