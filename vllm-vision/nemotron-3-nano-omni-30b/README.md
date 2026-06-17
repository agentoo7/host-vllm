# Nemotron 3 Nano Omni 30B-A3B — FP8 (vLLM)

OpenAI-compatible endpoint for [`nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8`](https://huggingface.co/nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8)
— NVIDIA's hybrid Mamba2-Transformer MoE (~3B active). The **fullest omni model** in the
lineup: **audio + video + image + text + docs** input. Vision = C-RADIO v4-H, speech =
Parakeet. Served with vLLM `0.22.1` + the `[audio]` extra.

## Run

```bash
docker compose up -d        # first run builds vllm-audio:0.22.1 (~15s) + downloads ~33 GB weights
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

> Uses the shared `vllm-audio:0.22.1` image (`vllm/vllm-openai:v0.22.1` + `vllm[audio]`,
> see `Dockerfile`). Built once and reused with `gemma-4-12b` — **no per-boot pip install**.

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8` |
| Max context | `131072` tokens (model supports 256K) |
| Modalities | text + image + video + **audio** + docs |
| Local media dir | host `./data` → container `/data` |

---

## Test with cURL

### 1. List models (health check)

```bash
curl -s http://localhost:20012/v1/models \
  -H "Authorization: Bearer lvm-apikey" | python3 -m json.tool
```

### 2. Text chat completion (reasoning)

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8",
    "messages": [{"role": "user", "content": "Reason step by step: if it takes 5 machines 5 minutes to make 5 widgets, how long for 100 machines to make 100 widgets?"}],
    "max_tokens": 512
  }' | python3 -m json.tool
```

### 3. Image input (remote URL)

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image_url", "image_url": {"url": "http://images.cocodataset.org/val2017/000000039769.jpg"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 4. Video input (local file)

```bash
# host: copy a video into ./data first, e.g. ./data/clip.mp4
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Summarize what happens in this video."},
        {"type": "video_url", "video_url": {"url": "file:///data/clip.mp4"}}
      ]}
    ],
    "max_tokens": 512
  }' | python3 -m json.tool
```

### 5. Audio input (local file)

```bash
# host: copy an audio file into ./data first, e.g. ./data/speech.wav
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Transcribe and summarize this audio."},
        {"type": "audio_url", "audio_url": {"url": "file:///data/speech.wav"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 6. Tool calling

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8",
    "messages": [{"role": "user", "content": "What is the weather in San Francisco?"}],
    "tools": [{"type": "function", "function": {
      "name": "get_weather",
      "description": "Get the current weather in a location",
      "parameters": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]}
    }}],
    "tool_choice": "auto"
  }' | python3 -m json.tool
```

---

## Notes

- FP8 ~33 GB → fits comfortably; FP8 is native on Ada. `--gpu-memory-utilization 0.85`
  leaves headroom for the multimodal encoders + long-context KV.
- Reasoning is toggled per-request via `enable_thinking` (no separate non-reasoning repo).
  Parser is **`nemotron_v3`** (the Super 120B uses a different `super_v3` plugin — don't
  mix them up).
- Audio support comes from the shared `vllm-audio:0.22.1` image (see `Dockerfile`; built
  once, reused with `gemma-4-12b`); mamba kernels are bundled with vLLM 0.22.1.
  `--trust-remote-code` is required.
- `--video-pruning-rate 0.5` + `--media-io-kwargs` control video frame sampling; tune for
  quality vs cost.
- **Do not** use the `-NVFP4` variant — Ada has no FP4 hardware.
