# DiffusionGemma 26B-A4B (vLLM, diffusion build)

OpenAI-compatible endpoint for [`google/diffusiongemma-26B-A4B-it`](https://huggingface.co/google/diffusiongemma-26B-A4B-it)
— Google's **block-diffusion** LLM on the Gemma 4 26B A4B base (~3.8B active). Text +
image + video **input**, text **output**, up to ~4x the speed of autoregressive decoding.

> ⚠️ **Experimental.** Diffusion decoding is a different inference path: stock vLLM
> **cannot** load this model — it needs the diffusion-enabled `vllm/vllm-openai:gemma`
> image and diffusion-specific flags. Quality is **lower** than standard Gemma 4 26B; use
> only for speed-critical work (autocomplete, inline editing). Flag names below may need
> tuning against the image's `vllm serve --help`.

## Run

```bash
docker compose up -d        # downloads weights (~52 GB BF16) on first run
docker compose logs -f      # ready when you see "Application startup complete."
docker compose down
```

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | `google/diffusiongemma-26B-A4B-it` |
| Max context | `262144` tokens |
| Modalities | text + image + video input → text output |
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
    "model": "google/diffusiongemma-26B-A4B-it",
    "messages": [{"role": "user", "content": "Write a Python function that reverses a linked list."}],
    "max_tokens": 256
  }' | python3 -m json.tool
```

### 3. Code-completion style prompt (the intended fast use case)

```bash
curl -s http://localhost:20012/v1/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/diffusiongemma-26B-A4B-it",
    "prompt": "def quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n",
    "max_tokens": 200
  }' | python3 -m json.tool
```

### 4. Image input (remote URL)

```bash
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "google/diffusiongemma-26B-A4B-it",
    "messages": [
      {"role": "user", "content": [
        {"type": "text", "text": "Describe this image."},
        {"type": "image_url", "image_url": {"url": "http://images.cocodataset.org/val2017/000000039769.jpg"}}
      ]}
    ],
    "max_tokens": 200
  }' | python3 -m json.tool
```

---

## Notes

- Requires the diffusion build image `vllm/vllm-openai:gemma`. Stock `vllm/vllm-openai`
  will fail to load the architecture.
- `--max-num-seqs 4` is **critical** — the diffusion canvas buffers OOM at higher
  concurrency.
- `--generation-config vllm`, `--hf-overrides '{"diffusion_sampler": ...}'` and
  `--diffusion-config '{"canvas_length": 256}'` are diffusion-specific; verify exact names
  with `docker compose run --rm diffusiongemma-hosting --help` if startup rejects a flag.
- BF16 ~52 GB exceeds one 48 GB L40 → `--tensor-parallel-size 2`. (An NVFP4 ~18 GB variant
  exists but Ada has no FP4 — prefer BF16, which fits across both GPUs.)
- Output is **text only**; image/video are input-only.
