# Nemotron 3 Super 120B-A12B — 4-bit GGUF via llama.cpp

OpenAI-compatible endpoint for [`unsloth/NVIDIA-Nemotron-3-Super-120B-A12B-GGUF`](https://huggingface.co/unsloth/NVIDIA-Nemotron-3-Super-120B-A12B-GGUF)
— NVIDIA's hybrid Latent-MoE (120B total / 12B active, text-only, **1M context**),
leading its size class on AIME / Terminal Bench / SWE-Bench Verified. Served with
**llama.cpp** (not vLLM).

> ⚠️ **Why llama.cpp, not vLLM.** FP8 is ~120 GB and does **not** fit 96 GB
> (NVIDIA recommends 2×H100). The only thing that fits 2x L40 is a **4-bit quant**, and
> vLLM cannot serve this model's GGUF. llama.cpp's `server` is OpenAI-compatible, so the
> API surface (`/v1/...`, bearer key) is identical to the other folders.
> See the bottom for an experimental vLLM-AWQ alternative.

## Run

```bash
docker compose up -d        # downloads the UD-IQ4_XS shards (~64.5 GB) on first run
docker compose logs -f      # ready when llama.cpp prints "server is listening"
docker compose down
```

The ~64.5 GB download is slow — track it (with speed/ETA + auto-restart on stall) via:

```bash
./monitor.sh         # optional interval arg in seconds, e.g. ./monitor.sh 15
```

> Weights land in `~/.cache/llama.cpp` (mounted as a volume so they persist across
> restarts), not the HF hub cache — that's what `monitor.sh` watches.

| | |
|---|---|
| Base URL | `http://localhost:20012/v1` |
| API key | `lvm-apikey` |
| Model id | (llama.cpp reports the loaded GGUF path; the `"model"` field is ignored — any string works) |
| Max context | `131072` here (1M not reachable on 96 GB; ~128–256K realistic at 4-bit) |
| Modalities | text only |

---

## Test with cURL

llama.cpp's server ignores the `"model"` field, but it must be present. Use the placeholder
`nemotron-super` below.

### 1. List models / health

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
    "model": "nemotron-super",
    "messages": [{"role": "user", "content": "Prove that the square root of 2 is irrational. Reason carefully."}],
    "max_tokens": 768,
    "temperature": 1.0,
    "top_p": 0.95
  }' | python3 -m json.tool
```

### 3. Streaming response

```bash
curl -N -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "nemotron-super",
    "messages": [{"role": "user", "content": "Count from 1 to 5."}],
    "max_tokens": 64,
    "stream": true
  }'
```

### 4. Long-context (paste a large file/codebase)

```bash
# Build a payload with a big context block and ask a question about it.
python3 - <<'PY'
import json
ctx = open("data/bigfile.txt").read()   # put a large text file under ./data first
json.dump({
  "model": "nemotron-super",
  "messages": [
    {"role": "user", "content": f"Here is a document:\n\n{ctx}\n\nSummarize its key points."}
  ],
  "max_tokens": 512, "temperature": 1.0, "top_p": 0.95
}, open("/tmp/payload.json", "w"))
PY
curl -s http://localhost:20012/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" \
  -H "Content-Type: application/json" \
  --data-binary @/tmp/payload.json | python3 -m json.tool
```

---

## Notes

- **Quant choice.** `UD-IQ4_XS` (~64.5 GB) is the best-fitting 4-bit. Other tags from the
  same repo also fit and trade size for quality: `UD-Q4_K_S` (~79 GB),
  `UD-Q4_K_M` (~82.5 GB). Change the `:TAG` after the repo in `docker-compose.yml`.
- `--tensor-split 1,1` spreads layers evenly across the two L40s; `-ngl 999` offloads all
  layers to GPU. `--special` keeps the `<think>`/`</think>` reasoning tokens visible.
- Recommended sampling per the model card: `temperature 1.0`, `top_p 0.95`.
- 1M context won't fit on 96 GB — `--ctx-size` is set to 131072; raise toward 256K only if
  VRAM allows.
- **Experimental vLLM alternative** (OpenAI-native, but unvalidated): a community AWQ
  exists — [`cyankiwi/NVIDIA-Nemotron-3-Super-120B-A12B-AWQ-4bit`](https://huggingface.co/cyankiwi/NVIDIA-Nemotron-3-Super-120B-A12B-AWQ-4bit).
  To try it, swap the service for `vllm/vllm-openai` with:
  `--quantization awq_marlin --tensor-parallel-size 2 --trust-remote-code
  --reasoning-parser super_v3 --tool-call-parser qwen3_coder
  --mamba-ssm-cache-dtype float16 --enable-chunked-prefill`. Treat as experimental.
