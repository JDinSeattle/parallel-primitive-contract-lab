# Local upstream review packet

Status: prepared locally; not posted or submitted. Existing upstream PR #10993 owns the fix.

The pinned base/head in `manifests/versions.json` were compiled with the same source and compiler options. The base has 20 failures among 38 cases; patched head passes all 38. Evidence includes signed minimal values, output bin-index boundaries, full int16 sample range, plain char, and 64-bit unsigned counters. All output guard checks pass for the patched revision. CPU ASan/UBSan and GPU memcheck/racecheck logs are attached in the measured report.

Reviewers can run one four-sample reproduction via the binary's `minimal` mode and then use the full matrix. The test cases do not claim coverage of multichannel APIs, floating bin levels or other SM architectures. Per-round performance arrays quantify the signed-positive dispatch cost and unchanged unsigned control behavior on the available device.

Before any future upstream contribution, recheck PR status and discuss whether additional type/stride/performance coverage is useful. A passing independent reproduction is evidence, not a reason to duplicate the author's patch. No untested patch artifact is presented as integrated upstream code.
