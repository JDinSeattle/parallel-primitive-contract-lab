# Checkout validation

This local validation is separate from the user-confirmed cloud results in the README.

18 pytest passed; Clang ASan/UBSan oracle passed 264 checks (includes one newly added minimal signed-byte case). detect_leaks=0.

## Commands

```text
/home/postedism/Desktop/compliers/C-gpu-codegen-qualification/.venv/bin/python -m pytest -q -ra
```

```text
clang++ -std=c++17 -O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer -Wall -Wextra -Werror -Iinclude tests/oracle_test.cpp -o build/oracle-sanitized
```

```text
ASAN_OPTIONS=detect_leaks=0 ./build/oracle-sanitized
```

No new physical-GPU performance, cloud rerun, or production availability claim is made. Local build and runtime artifacts remain outside Git; the committed source and profiles reproduce the checks with the pinned dependencies. Historical source changes already present in the user’s working tree are preserved in this update.
