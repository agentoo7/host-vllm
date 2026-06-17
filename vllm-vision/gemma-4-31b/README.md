# Gemma 4 31B Instruct — FP8 (vLLM)

OpenAI-compatible endpoint for [`RedHatAI/gemma-4-31B-it-FP8-block`](https://huggingface.co/RedHatAI/gemma-4-31B-it-FP8-block)
— Google's 31B dense multimodal (text + image + video) model, FP8-block quantized
(vision tower kept at higher precision), served with vLLM `0.22.1`.

**All-round pick** for the 2x L40 box: highest quality that fits comfortably, 256K-capable
context (capped to 131072 here for KV-cache headroom), multimodal, tool + reasoning support.

## Run

```bash
docker compose up -d        # downloads weights (~35 GB FP8) on first run
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `RedHatAI/gemma-4-31B-it-FP8-block` |
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
    "model": "RedHatAI/gemma-4-31B-it-FP8-block",
    "messages": [{"role": "user", "content": "Explain tensor parallelism in two sentences."}],
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
    "model": "RedHatAI/gemma-4-31B-it-FP8-block",
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
    "model": "RedHatAI/gemma-4-31B-it-FP8-block",
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

Put the file under `./data` (appears at `/data` in the container), then use a `file://` URL:

```bash
# host: copy an image into ./data first, e.g. ./data/cats.jpg
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/gemma-4-31B-it-FP8-block",
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
    "model": "RedHatAI/gemma-4-31B-it-FP8-block",
    "messages": [{"role": "user", "content": "What is the weather in San Francisco?"}],
    "tools": [{"type": "function", "function": {
      "name": "get_weather",
      "description": "Get the current weather in a location",
      "parameters": {"type": "object", "properties": {"location": {"type": "string"}}, "required": ["location"]}
    }}],
    "tool_choice": "auto"
  }' | python3 -m json.tool
```

### 7. Text completions endpoint (non-chat)

```bash
curl -s http://localhost:20012/v1/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "RedHatAI/gemma-4-31B-it-FP8-block",
    "prompt": "The three laws of motion are:",
    "max_tokens": 200,
    "temperature": 0.2
  }' | python3 -m json.tool
```

---

## Notes

- **FP8 is native on the L40 (Ada)** — weights ~35 GB, split TP=2 ≈ 17.5 GB/GPU,
  leaving ~30 GB/GPU for KV cache. Raise `--max-model-len` toward 256K if you need it
  and have cache headroom; lower `--gpu-memory-utilization` if you hit OOM.
- The FP8-**block** variant keeps the vision tower / embeddings / head in higher
  precision → better multimodal quality than a fully-dynamic FP8 quant.
- Parsers/template are Gemma-4 specific: `--reasoning-parser gemma4`,
  `--tool-call-parser gemma4`, `--chat-template examples/tool_chat_template_gemma4.jinja`
  (ships inside the vLLM image). No `--trust-remote-code` needed.
- **Do not** use `*-NVFP4` repos — Ada has no FP4 hardware.
