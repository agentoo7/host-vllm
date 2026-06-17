# Gemma 4 12B is encoder-free "Unified" — its support landed in vLLM PR #44429 and is
# NOT in any stable release (v0.22.1 falls back to a broken generic wrapper). NVIDIA/vLLM
# ship a dedicated image with the native impl: vllm/vllm-openai:gemma4-unified.
# We add the audio runtime libs on top (the [audio] extra) without touching the special
# vLLM build. Built once -> tagged vllm-gemma4-unified:audio.
# Ref: https://recipes.vllm.ai/Google/gemma-4-12B-it
FROM vllm/vllm-openai:gemma4-unified
RUN pip install --no-cache-dir soundfile librosa soxr av
