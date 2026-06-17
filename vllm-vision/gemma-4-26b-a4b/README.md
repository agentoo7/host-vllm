# Gemma 4 26B A4B Instruct — FP8 (vLLM)

OpenAI-compatible endpoint for [`RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic`](https://huggingface.co/RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic)
— Google's MoE model (26B total / ~3.8B active), multimodal (text + image + video),
FP8 quantized, served with vLLM `0.22.1`.

**Speed + quality pick** for agent workloads: only ~3.8B active params → much higher
throughput on the L40 than the 31B dense model, Arena score only ~11 points behind.

## Run

```bash
docker compose up -d        # downloads weights (~29 GB FP8) on first run
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic` |
| Max context | `131072` tokens (model supports 256K) |
| Modalities | text + image + video (no audio) |
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
    "model": "RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic",
    "messages": [{"role": "user", "content": "Give me a 3-step plan to debug a flaky test."}],
    "max_tokens": 256,
    "temperature": 0.2
  }' | python3 -m json.tool
```

### 3. Streaming response

```bash
curl -N -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic",
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
    "model": "RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Describe what is happening in this image."},
        {"type": "image_url", "image_url": {"url": "http://images.cocodataset.org/val2017/000000039769.jpg"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 5. Image input (local file)

```bash
# host: copy an image into ./data first, e.g. ./data/cats.jpg
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "What objects are in this image?"},
        {"type": "image_url", "image_url": {"url": "file:///data/cats.jpg"}}
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
    "model": "RedHatAI/gemma-4-26B-A4B-it-FP8-Dynamic",
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

- FP8 weights ~29 GB → the **most headroom** of the three Gemma configs; can serve very
  long context and high concurrency. `--gpu-memory-utilization 0.90`.
- MoE: optionally add `--enable-expert-parallel` and benchmark — not required at TP=2.
- Gemma-4 parsers/template as above; no `--trust-remote-code`.
- **Do not** use `*-NVFP4` repos — Ada has no FP4 hardware.
