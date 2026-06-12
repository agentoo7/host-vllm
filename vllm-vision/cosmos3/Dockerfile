# Cosmos3-Nano reasoner image.
#
# The stock vllm/vllm-openai images do NOT know the `cosmos3_omni` model type /
# `Cosmos3ReasonerForConditionalGeneration` architecture — that code ships in
# NVIDIA's separate `vllm-cosmos3` plugin. Per NVIDIA's cosmos3 cookbook, the
# reasoner path pins vLLM 0.21.0 on the cu130 torch backend (CUDA 13 drivers).
#
# Refs:
#   https://github.com/NVIDIA/cosmos/tree/main/cookbooks/cosmos3
#   https://huggingface.co/nvidia/Cosmos3-Nano

# uv base already ships Python 3.13 + uv; torch cu130 wheels bundle the CUDA
# userspace libs, and the NVIDIA container runtime injects the driver at run.
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        git curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/venv
RUN uv venv --seed "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# vLLM 0.21.0 (cu130) + NVIDIA's Cosmos3 reasoner plugin + openai client.
RUN uv pip install --torch-backend=cu130 \
        "vllm==0.21.0" \
        "vllm-cosmos3 @ git+https://github.com/NVIDIA/cosmos-framework.git#subdirectory=packages/vllm-cosmos3" \
        openai

# Triton JIT-compiles its CUDA driver utils at runtime and needs a C compiler
# (gcc) + Python headers. Kept after the pip layer so that expensive layer
# stays cached when this changes.
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential python3-dev && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 6000

# Matches the stock vllm-openai entrypoint so the compose `command:` (which
# begins with `--model ...`) works unchanged.
ENTRYPOINT ["vllm", "serve"]
