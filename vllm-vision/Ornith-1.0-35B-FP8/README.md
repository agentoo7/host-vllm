# Ornith-1.0-35B-FP8 — Vision + Coding (2× L40)

Self-scaffolding agentic-coding **VL (vision-language) MoE** của DeepReinforce AI,
kiến trúc **Qwen3.5-VL** (`Qwen3_5MoeForConditionalGeneration`, MoE ~A3B active), hybrid
GDN + Mamba. Nhận **cả text lẫn ảnh/video**. Reasoning model (có thể mở block `<think>`,
trả về ở `reasoning_content`).

## ⚠️ Dùng bản re-quant protoLabsAI, KHÔNG dùng FP8 chính thức trên L40

- Repo dùng: **[`protoLabsAI/Ornith-1.0-35B-FP8`](https://huggingface.co/protoLabsAI/Ornith-1.0-35B-FP8)**
- Bản FP8 **chính thức `deepreinforce-ai/Ornith-1.0-35B-FP8` BỊ LỖI trên L40/Ada**: nó
  quantize FP8 cả layer SSM/linear-attention và có layer dim **2152** (không chia hết 16).
  Trên Ada (SM 8.9, không phải Hopper) không kernel FP8 nào nạp được:
  - Cutlass FP8 → bug `AssertionError: Overwriting existing tensor attribute: weight_loader`
  - Torch FP8 → `mat2 shape (1152x2152) must be divisible by 16`
  - Marlin FP8 → `size_n = 2152 is not divisible by tile_n_size = 64`
- protoLabsAI re-quant giữ **bf16** cho `linear_attn.*`, `mlp.gate`, `shared_expert_gate`,
  vision tower, norms, embed, lm_head; chỉ FP8 cho expert FFN + attention q/k/v/o.
  vLLM chọn `TritonFp8BlockScaledMMKernel` (block-scaled FP8 chạy Triton) → nạp tốt trên L40.

## Chạy (đã verify chạy được)

```bash
docker compose up -d
docker compose logs -f          # doi "Application startup complete"
```

- Image: **`vllm/vllm-openai:v0.25.1`** (cần bản mới để nhận arch Qwen3.5-VL MoE).
- Endpoint OpenAI-compatible: `http://<host>:20014/v1`, API key `lvm-apikey`,
  model name `Ornith-1.0-35B`.
- Weights ~38–40GB (nhiều layer bf16), TP=2 trên 2× L40 (96GB); `--max-model-len 204800` (200k).
- Lần đầu tải model qua HF Xet ~35–40GB (staging ở `~/.cache/huggingface/xet` rồi mới ghép).

## Test text

```bash
curl http://localhost:20014/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" -H "Content-Type: application/json" \
  -d '{"model":"Ornith-1.0-35B","messages":[{"role":"user","content":"Reverse a string in Python, one line."}],"max_tokens":800}'
```

## Test vision (ảnh + text)

```bash
curl http://localhost:20014/v1/chat/completions \
  -H "Authorization: Bearer lvm-apikey" -H "Content-Type: application/json" \
  -d '{
    "model": "Ornith-1.0-35B",
    "max_tokens": 1200,
    "messages": [{"role":"user","content":[
      {"type":"text","text":"Describe what is in this image."},
      {"type":"image_url","image_url":{"url":"https://example.com/screenshot.png"}}
    ]}]
  }'
```

Lưu ý: đây là reasoning model — nếu `content` rỗng và `finish_reason=length`, tăng
`max_tokens` (model tiêu token trong reasoning trước khi ra câu trả lời).

## Ghi chú cấu hình

- `--tool-call-parser qwen3_xml`, `--reasoning-parser qwen3` (theo model card).
- `--trust-remote-code` bắt buộc; FP8 vLLM tự nhận (không cần `--quantization`).
- `--disable-custom-all-reduce`: L40 không có NVLink/P2P → tránh treo all-reduce.
- `--limit-mm-per-prompt '{"image": 8, "video": 1}'` — giới hạn ảnh/video mỗi prompt.
- Nếu OOM: giảm `--max-model-len`, `--gpu-memory-utilization` (đang 0.88), hoặc `--max-num-seqs`.
