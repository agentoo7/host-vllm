# Shared vLLM image with the [audio] extra baked in, so audio-capable models
# (gemma-4-12b, nemotron-3-nano-omni) start WITHOUT a per-boot pip install.
# Build once -> tagged vllm-audio:0.22.1 -> reused by both folders.
FROM vllm/vllm-openai:v0.22.1
RUN pip install --no-cache-dir vllm[audio]==0.22.1
