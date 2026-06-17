# Mistral Small 4 (119B-A6.5B) — NVFP4 (vLLM)

OpenAI-compatible endpoint for [`mistralai/Mistral-Small-4-119B-2603-NVFP4`](https://huggingface.co/mistralai/Mistral-Small-4-119B-2603-NVFP4)
— Mistral's MoE (119B total / 6.5B active) with Pixtral vision (text + image), 256K
context. Served with vLLM `0.22.1` using Mistral's native tokenizer/config/format.

> ⚠️ **Ada / L40 caveat.** Full FP8 is ~111 GB and does **not** fit 96 GB. NVFP4 is the
> only quant that fits in vLLM — but Ada (sm89) has **no FP4 hardware**, so NVFP4 runs via
> **software dequant** (works, but slower than native). If throughput is unacceptable, use
> the **llama.cpp GGUF** path documented at the bottom.

## Run

```bash
docker compose up -d        # downloads NVFP4 weights (~62 GB) on first run
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

The ~62 GB download is slow — track it (with speed/ETA + auto-restart on stall) via:

```bash
./monitor.sh         # optional interval arg in seconds, e.g. ./monitor.sh 15
```

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `mistralai/Mistral-Small-4-119B-2603-NVFP4` |
| Max context | `65536` tokens (model supports 256K; capped for VRAM) |
| Modalities | text + image |
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
    "model": "mistralai/Mistral-Small-4-119B-2603-NVFP4",
    "messages": [{"role": "user", "content": "Write a haiku about GPUs."}],
    "max_tokens": 128
  }' | python3 -m json.tool
```

### 3. Streaming response

```bash
curl -N -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistralai/Mistral-Small-4-119B-2603-NVFP4",
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
    "model": "mistralai/Mistral-Small-4-119B-2603-NVFP4",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image_url", "image_url": {"url": "http://images.cocodataset.org/val2017/000000039769.jpg"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 5. Tool calling

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "mistralai/Mistral-Small-4-119B-2603-NVFP4",
    "messages": [{"role": "user", "content": "What is the weather in Paris?"}],
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

- Mistral models require `--tokenizer-mode mistral --config-format mistral
  --load-format mistral` — without these the tokenizer/prompt template are wrong.
- NVFP4 on Ada is software-dequant; lower `--max-model-len` / `--gpu-memory-utilization`
  if you hit OOM, and expect lower throughput than an FP8 model of similar size.
- **llama.cpp GGUF fallback** (faster on Ada, but vision support varies): use
  [`unsloth/Mistral-Small-4-119B-2603-GGUF`](https://huggingface.co/unsloth/Mistral-Small-4-119B-2603-GGUF)
  `Q4_K_M` (~73.8 GB) or `IQ4_XS` (~58 GB) with the llama.cpp server image
  (`ghcr.io/ggml-org/llama.cpp:server-cuda`, see the `nemotron-3-super-120b/` folder for
  the compose shape: `-hf <repo>:Q4_K_M --tensor-split 1,1 -ngl 999 --port 6000 --api-key lvm-apikey`).
- **Do not** expect FP4 acceleration — Ada has none.
