# Gemma 4 12B Instruct — Unified, with audio (vLLM)

OpenAI-compatible endpoint for [`google/gemma-4-12B-it`](https://huggingface.co/google/gemma-4-12B-it)
— Google's 12B dense **encoder-free Unified** model. It's the only Gemma 4 that takes
**audio** (16 kHz waveforms) in addition to text + image + video. Served with the
dedicated **`vllm/vllm-openai:gemma4-unified`** image + audio libs.

## Run

```bash
docker compose up -d        # first run builds vllm-audio:0.22.1 (~15s) + downloads ~12 GB weights
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

> First `up` builds `vllm-gemma4-unified:audio` (`vllm/vllm-openai:gemma4-unified` + audio
> libs, see `Dockerfile`). Subsequent starts reuse it — no per-boot pip install.

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `google/gemma-4-12B-it` |
| Max context | `131072` tokens (model supports 256K) |
| Modalities | text + image + video + **audio** |
| Local media dir | host `./data` → container `/data` |

---

## Test with cURL

### 1. List models (health check)

```bash
curl -s http://localhost:20012/v1/models \
  -H "Authorization: Bearer lvm-apikey" | python3 -m json.tool
```

### 2. Text chat completion

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-4-12B-it",
    "messages": [{"role": "user", "content": "Summarize the plot of Romeo and Juliet in 3 sentences."}],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 3. Streaming response

```bash
curl -N -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-4-12B-it",
    "messages": [{"role": "user", "content": "Count from 1 to 5."}],
    "max_tokens": 64,
    "stream": true
  }'
```

### 4. Image input (remote URL)

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-4-12B-it",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Describe what is happening in this image."},
        {"type": "image_url", "image_url": {"url": "http://images.cocodataset.org/val2017/000000039769.jpg"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 5. Audio input (local file)

```bash
# host: copy a 16 kHz wav/mp3 into ./data first, e.g. ./data/speech.wav
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/gemma-4-12B-it",
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
    "model": "google/gemma-4-12B-it",
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

- **Why a special image:** the encoder-free 12B Unified architecture landed in vLLM
  PR #44429 and is **not in any stable release** — on `v0.22.1` it falls back to a generic
  `TransformersMultiModalForCausalLM` wrapper that crashes with a linear-layer shape
  mismatch (`mat1 and mat2 shapes cannot be multiplied`). The `gemma4-unified` image has
  the native impl. Ref: https://recipes.vllm.ai/Google/gemma-4-12B-it
- Runs single-GPU (`--tensor-parallel-size 1`); the model is ~24 GB BF16, fits one L40.
- Audio libs (`soundfile librosa soxr av`) are baked into `vllm-gemma4-unified:audio` via
  `Dockerfile` — built once, no per-boot pip.
- **Audio** is enabled via `--limit-mm-per-prompt '{"image":4,"audio":1}'`. Send audio
  as an `audio_url` content part (remote URL, `file:///data/...`, or `data:` base64).
- At only ~12 GB BF16 this fits on a **single** L40 — drop to
  `--tensor-parallel-size 1` to free the other GPU if you don't need long context.
- Context: the doc said 128K but the official 12B card is **256K**; capped to 131072
  here. Raise toward 256K if you have KV-cache headroom.
- **Do not** use `*-NVFP4` repos — Ada has no FP4 hardware.
