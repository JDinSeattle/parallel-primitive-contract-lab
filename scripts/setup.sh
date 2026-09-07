#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .deps build
for revision in 46a37f86b650bfc90b6cd852771bd31952688097 a7f211c17cd15673d4bc8dbe2215c6952d9a1aef; do
  if [ ! -d ".deps/$revision" ]; then
    curl -fL --retry 3 "https://api.github.com/repos/NVIDIA/cccl/tarball/$revision" -o ".deps/$revision.tar.gz"
    mkdir -p ".deps/$revision"
    tar -xzf ".deps/$revision.tar.gz" --strip-components=1 -C ".deps/$revision"
  fi
  nvcc -std=c++17 -O3 -lineinfo -arch="sm_${CUDA_ARCH:-89}" \
    -Iinclude -I".deps/$revision/cub" -I".deps/$revision/thrust" -I".deps/$revision/libcudacxx/include" \
    src/histogram_probe.cu -o "build/$revision"
done
g++ -std=c++17 -O2 -Wall -Wextra -Werror -Iinclude tests/oracle_test.cpp -o build/oracle_test
