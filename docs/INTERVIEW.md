# Interview and résumé evidence

Suggested résumé bullet:

> Developed a C++/CUDA histogram contract harness with an independent interval oracle, 263 CPU checks and 38 GPU cases; reproduced 20 failures in a pinned CUB revision, independently validated an existing upstream fix, and measured signed-dispatch and unsigned fast-path regressions under sanitizers.

This supports C++ GPU-library, numerical correctness and regression-engineering roles. It is not a claim to have authored or merged the upstream fix.

Explain the distinction between sample type, level type, bin-index type and counter type. Show why negative signed-byte samples vanish in the byte pass-through path, and why eliminating that dispatch alone does not fix a later narrowing cast of bin indices. Explain why `int64_t` and `unsigned long long` are not interchangeable just because they can both be 64 bits.

Demonstrate `build/<base> minimal` returning failure and `build/<fixed> minimal` returning success. Then show the unsigned control and signed-positive performance distribution, including any slowdown. The strongest evidence is a test that proves the detector can fail and a root-cause explanation that survives adjacent types.
