# Cosmos3-Nano Reasoner (vLLM)

OpenAI-compatible inference endpoint for [`nvidia/Cosmos3-Nano`](https://huggingface.co/nvidia/Cosmos3-Nano),
a multimodal (text + image + video) physical-AI reasoner, served with vLLM
`0.21.0` + NVIDIA's `vllm-cosmos3` plugin.

## Run

```bash
docker compose up -d        # first run builds the custom image (~12 min) + downloads weights (~32 GB)
docker compose logs -f      # watch startup; ready when you see "Application startup complete."
docker compose down         # stop
```

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `nvidia/Cosmos3-Nano` |
| Max context | `131072` tokens |
| Local media dir | host `./data` → container `/data` |

> First startup is slow: it builds the image, downloads weights, then runs
> `torch.compile` + CUDA-graph capture. The container shows `healthy` once the
> HTTP server is up.

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
    "model": "nvidia/Cosmos3-Nano",
    "messages": [
      {"role": "user", "content": "A ball is dropped from 10 m. Roughly how long until it hits the ground? Reason briefly."}
    ],
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
    "model": "nvidia/Cosmos3-Nano",
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
    "model": "nvidia/Cosmos3-Nano",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Describe what is happening in this image."},
        {"type": "image_url", "image_url": {"url": "http://images.cocodataset.org/val2017/000000039769.jpg"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

> Remote URLs are fetched **server-side**. Some hosts (e.g. Wikimedia) reject
> requests without a browser User-Agent and return `403` — prefer a
> hotlink-friendly host like the COCO sample above, or use a local file.

### 5. Image input (local file)

Put the file under `./data` on the host (it appears at `/data` in the container),
then reference it with a `file://` URL:

```bash
# host: copy an image into ./data first, e.g. ./data/cats.jpg
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Cosmos3-Nano",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "What objects are in this image?"},
        {"type": "image_url", "image_url": {"url": "file:///data/cats.jpg"}}
      ]}
    ],
    "max_tokens": 256
  }' | python3 -m json.tool
```

You can also inline an image as base64. Build the JSON into a file first — a
base64 image is too large to pass inline as a shell argument (`Argument list too
long`):

```bash
python3 - <<'PY'
import base64, json
b64 = base64.b64encode(open("data/cats.jpg", "rb").read()).decode()
json.dump({
  "model": "nvidia/Cosmos3-Nano",
  "messages": [{"role": "user", "content": [
    {"type": "text", "text": "Describe this image."},
    {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + b64}}
  ]}],
  "max_tokens": 256,
}, open("/tmp/payload.json", "w"))
PY
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/payload.json | python3 -m json.tool
```

### 6. Video input (local file)

```bash
# host: copy a video into ./data first, e.g. ./data/clip.mp4
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Cosmos3-Nano",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Summarize what happens in this video."},
        {"type": "video_url", "video_url": {"url": "file:///data/clip.mp4"}}
      ]}
    ],
    "max_tokens": 512
  }' | python3 -m json.tool
```

### 7. Text completions endpoint (non-chat)

```bash
curl -s http://localhost:20012/v1/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nvidia/Cosmos3-Nano",
    "prompt": "The three laws of motion are:",
    "max_tokens": 200,
    "temperature": 0.2
  }' | python3 -m json.tool
```

---

## Notes

- **Local media** must live under `./data` (mounted at `/data`); reference it as
  `file:///data/<name>`. Remote `http(s)://` URLs and `data:` base64 URLs also work.
- The serving model id is exactly `nvidia/Cosmos3-Nano` — it must match the
  `"model"` field in every request.
- The **L40 (Ada)** GPU is not on NVIDIA's officially-tested list
  (Ampere/Hopper/Blackwell); it runs but isn't a release-tested config.
- Context is capped at `131072` (default 256K won't fit the L40's KV cache on a
  single GPU). Raise it by using both GPUs (`--tensor-parallel-size 2`) or
  lowering further if you hit OOM.
