#!/bin/bash
# Build llama.cpp llama-bench for GB10 (sm_121) inside the NGC PyTorch container. Records the commit.
set -u
cd /home/milo/kbench
[ -d llama.cpp/.git ] && { cd llama.cpp; git log -1 --format="LLAMA_COMMIT %h %cd"; } || { rm -rf llama.cpp
git clone -q --depth 1 https://github.com/ggml-org/llama.cpp llama.cpp || { echo CLONE_FAIL; exit 1; }; cd llama.cpp; }

nice -n 10 docker run --rm -v /home/milo/kbench/llama.cpp:/src -w /src ${KB_IMG:-nvcr.io/nvidia/pytorch:25.09-py3} bash -c \
 "cmake -B ${KB_LLAMA_BUILD:-build-cu130} -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES=121 -DLLAMA_CURL=OFF >/dev/null && cmake --build ${KB_LLAMA_BUILD:-build-cu130} --target llama-bench -j 16 2>&1 | tail -3"
echo BUILD_RC=$?
