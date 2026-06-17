# gpt-oss-120b (vLLM)

OpenAI-compatible endpoint for [`openai/gpt-oss-120b`](https://huggingface.co/openai/gpt-oss-120b)
— OpenAI's open-weight MoE (117B total / 5.1B active), **text-only**, MXFP4 weights ship
in the repo. Strong math / tool-use / agentic reasoning (near o4-mini class).

> ⚠️ **Ada / L40 caveat.** MXFP4 is *not* hardware-accelerated on Ada (sm89) — it only
> has native support on Hopper/Blackwell/MI300. On the L40 it runs via **software
> dequant to bf16**, so the memory win shrinks and context is realistically capped
> around **32K** (not the model's 128K). It works, but it is not a release-tested config.

## Run

```bash
docker compose up -d        # downloads weights (~63 GB MXFP4) on first run
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

The ~63 GB download is slow — track it (with speed/ETA + auto-restart on stall) via:

```bash
./monitor.sh         # optional interval arg in seconds, e.g. ./monitor.sh 15
```

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `openai/gpt-oss-120b` |
| Max context | `32768` tokens (Ada dequant limit; model is 128K on Hopper+) |
| Modalities | text only |

---

## Test with cURL

### 1. List models (health check)

```bash
curl -s http://localhost:20012/v1/models \
  -H "Authorization: Bearer lvm-apikey" | python3 -m json.tool
```

### 2. Reasoning chat completion

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "A train travels 60 km in 45 minutes. What is its average speed in km/h? Show your reasoning."}],
    "max_tokens": 512,
    "temperature": 0.2
  }' | python3 -m json.tool
```

### 3. Streaming response

```bash
curl -N -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "Count from 1 to 5."}],
    "max_tokens": 64,
    "stream": true
  }'
```

### 4. Tool calling

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "messages": [{"role": "user", "content": "What is the weather in San Francisco?"}],
    "tools": [{"type": "function", "function": {
      "name": "get_weather",
      "description": "Get the current weather in a location",
      "parameters": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]}
    }}],
    "tool_choice": "auto"
  }' | python3 -m json.tool
```

### 5. Text completions endpoint (non-chat)

```bash
curl -s http://localhost:20012/v1/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-oss-120b",
    "prompt": "List three prime numbers greater than 100:",
    "max_tokens": 100
  }' | python3 -m json.tool
```

---

## Notes

- MXFP4 is **auto-detected** from the repo — no `--quantization` flag needed.
- `--no-enable-prefix-caching` is **required** on L40/L40S (prefix caching currently
  breaks the MXFP4 dequant path).
- Env `VLLM_ATTENTION_BACKEND=TRITON_ATTN_VLLM_V1` + `TORCH_CUDA_ARCH_LIST=8.9` keep the
  Triton kernels building for Ada.
- If startup OOMs or context is too tight, lower `--max-model-len` further or
  `--gpu-memory-utilization`.
- Text-only: no `--limit-mm-per-prompt`, no media mount needed.
