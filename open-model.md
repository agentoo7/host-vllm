# So sánh LLM Open-Weight (không dùng model Trung Quốc) cho Server 2x NVIDIA L40

> **Cập nhật:** 12/06/2026
> **Mục tiêu:** Chọn model multimodal, benchmark cao hoặc nhanh, self-host được trên 2x L40 (96GB VRAM)

---

## 1. Bối cảnh phần cứng

| Thông số | Giá trị | Ghi chú |
|---|---|---|
| GPU | 2x NVIDIA L40 (48GB GDDR6 mỗi card) | Tổng 96GB VRAM |
| Kiến trúc | Ada Lovelace (compute capability 8.9) | **Có FP8 native** → vLLM FP8 chạy tốt |
| FP4 / NVFP4 | ❌ Không có hardware acceleration | FP4 chỉ có trên Blackwell |
| NVLink | ❌ Không có | Tensor parallel 2 qua PCIe — OK cho inference TP=2 |
| Format khuyến nghị | **FP8** hoặc **AWQ/GPTQ 4-bit** | MXFP4 (gpt-oss) chạy được qua dequant |

---

## 2. Lưu ý: Cosmos 3 KHÔNG phải LLM chat

NVIDIA Cosmos 3 (công bố tại GTC Taipei / COMPUTEX, 5/2026) là **world foundation model cho Physical AI** — robotics, xe tự hành, video world generation — kiến trúc Mixture-of-Transformers (omni-model):

- **Cosmos 3 Nano** — 16B (8B reasoner + 8B generator), chạy được trên workstation-class GPU
- **Cosmos 3 Super** — 64B (32B + 32B), nhắm GPU Hopper/Blackwell
- **Cosmos 3 Edge** — sắp ra mắt, cho edge inference

→ Nếu mục tiêu là LLM cho chat / coding / agent (KMS AgentOS) thì **bỏ qua Cosmos 3**. Chỉ đáng xét nếu bạn làm video generation hoặc physical AI.

---

## 3. Bảng so sánh chính

| Model | Nguồn gốc / License | Kiến trúc | Multimodal | Context | VRAM (ước lượng) | Benchmark nổi bật |
|---|---|---|---|---|---|---|
| **Gemma 4 31B** | Google · Apache 2.0 | 31B dense | Text + ảnh + video | 256K | BF16 ~62GB (TP=2 vừa đẹp) · FP8 ~32GB | AIME 2026: **89.2%** · LiveCodeBench v6: **80.0%** · τ2-bench Retail: **86.4%** · LMArena text ~**1452** |
| **Gemma 4 26B A4B** | Google · Apache 2.0 | MoE 26B tổng / **4B active** | Text + ảnh + video | 256K | BF16 ~52GB · FP8 ~26GB | LMArena ~**1441** với chỉ 4B active → tốc độ rất cao |
| **Gemma 4 12B** | Google · Apache 2.0 | 12B dense | Text + ảnh + video + **audio** | 128K | BF16 ~24GB (1 GPU dư sức) · 4-bit ~6.7GB | MMLU Pro ~**77.2%** · GPQA Diamond ~**78.8%** · vượt Gemma 3 27B |
| **gpt-oss-120b** | OpenAI (Mỹ) · Apache 2.0 | MoE 117B / 5.1B active | ❌ Text-only | 128K | **MXFP4 ~63GB** → TP=2 chạy ngon | Gần ngang **o4-mini** về reasoning (AIME, MMLU, TauBench, HealthBench) |
| **Nemotron 3 Nano Omni 30B-A3B** | NVIDIA (Mỹ) · open | MoE Mamba-Transformer · 3B active | **Audio + video + ảnh + text + docs** | 256K | BF16 ~62GB · 8-bit ~36GB · 4-bit ~25GB | Omni model mạnh nhất trong size · vượt Qwen3-Omni-30B trên mọi benchmark |
| **Nemotron 3 Super 120B-A12B** | NVIDIA · open | MoE 120B / 12B active | Text | **1M** | FP16 ~240GB ❌ · **4-bit ~60–80GB** (chỉ chạy được bản 4-bit) | Dẫn đầu size class: **AIME 2025, Terminal Bench, SWE-Bench Verified** · RULER 1M tốt |
| **Mistral Small 4 (119B-A6.5B)** | Mistral (Pháp) · Apache 2.0 | MoE 128 experts · 6.5B active · Pixtral vision | Text + ảnh | 256K | FP8 ~111GB ❌ · **Q4_K_M ~72.6GB** (llama.cpp, chật) | MMLU-Pro **78.0** · GPQA Diamond **71.2** · vượt gpt-oss-120b trên LiveCodeBench với output ngắn hơn 20% |
| **DiffusionGemma 26B** | Google · Apache 2.0 | Diffusion trên nền Gemma 4 26B A4B (3.8B active) | Text + ảnh + video (input) | 256K | BF16 ~52GB · quantized ~18GB | Tốc độ tới **4x** autoregressive · 1000+ tok/s trên H100 · **nhưng chất lượng thấp hơn Gemma 4 26B trên mọi benchmark** |

### Loại khỏi danh sách (lý do)

| Model | Lý do loại |
|---|---|
| Qwen 3.5/3.6/3.7, DeepSeek V4/R1, GLM 5.x, Kimi K2.x, MiMo | Model Trung Quốc (theo yêu cầu) |
| Llama 4 Scout/Maverick (Meta) | Benchmark đã bị Gemma 4 vượt rõ rệt; license Llama Community (không phải Apache 2.0); Maverick 400B không vừa 96GB |
| Mistral Large 3 (675B MoE) | Quá lớn cho 96GB |
| Nemotron 3 Ultra (550B) | Quá lớn cho 96GB |
| Cosmos 3 Super 64B | Không phải chat LLM; nhắm Hopper/Blackwell |

---

## 4. Gợi ý chọn theo nhu cầu

### 🏆 All-round tốt nhất → **Gemma 4 31B (FP8, TP=2)**
- Chất lượng cao nhất trong nhóm vừa khít 96GB, multimodal, 256K context
- FP8 chỉ ~32GB weights → dư ~60GB cho KV cache → serve context dài + nhiều request song song
- Cùng gpt-oss là 2 lựa chọn open-weight gốc Mỹ **không vướng license** — Gemma 4 thắng về năng lực tổng quát, gpt-oss thắng về math reasoning

### ⚡ Tốc độ + chất lượng (workload agent nhiều bước, kiểu AgentOS) → **Gemma 4 26B A4B (FP8)**
- Chỉ 4B active → throughput trên L40 cao hơn hẳn 31B dense
- Điểm Arena chỉ thua 31B ~11 điểm → đáng đổi cho latency thấp

### 🧠 Reasoning / agentic text-only mạnh nhất → **gpt-oss-120b (MXFP4)**
- ~63GB, TP=2 chạy thoải mái; tool use và math rất tốt
- Nhược: không có vision; ở context cực dài (1M) đuối hẳn so với Nemotron 3 Super

### 🎤 Cần audio + video input thật sự → **Nemotron 3 Nano Omni 30B-A3B (FP8/8-bit)**
- Nhẹ, nhanh (3B active), đa phương thức đầy đủ nhất trong bảng

### 📚 Cần context 1M (codebase lớn, brownfield) → **Nemotron 3 Super 120B (4-bit)**
- Trên 96GB buộc xài bản 4-bit (GGUF/AWQ) — chấp nhận đánh đổi chút chất lượng, tooling phức tạp hơn

### 🚀 Tốc độ tuyệt đối (autocomplete, in-line editing) → **DiffusionGemma 26B**
- Experimental, chất lượng thấp hơn Gemma 4 chuẩn — chỉ dùng cho use case speed-critical

---

## 5. Combo đề xuất cho 2x L40

**Phương án A — Swap qua lại (vLLM):**
- **Gemma 4 26B A4B (FP8)** làm workhorse hằng ngày
- **gpt-oss-120b (MXFP4)** làm reasoner cho task khó

**Phương án B — Chạy đồng thời 2 model:**
- GPU 0: **Gemma 4 12B** (multimodal, có cả audio) — ~24GB BF16
- GPU 1: **gpt-oss-20b** hoặc **Nemotron 3 Nano** — text reasoning

**Phương án C — Một model duy nhất, chất lượng tối đa:**
- **Gemma 4 31B FP8, TP=2** — cân mọi thứ, KV cache dư dả

---

## 6. Nguồn tham khảo

- Gemma 4 (Hugging Face official blog): https://huggingface.co/blog/gemma4
- Gemma 4 benchmarks chi tiết: https://dev.to/aniruddhaadak/gemma-4-complete-guide-2026-architecture-benchmarks-deployment-3en9
- Gemma 4 12B specs: https://lushbinary.com/blog/gemma-4-12b-developer-guide-benchmarks-multimodal/
- DiffusionGemma (Google official): https://blog.google/innovation-and-ai/technology/developers-tools/diffusion-gemma-faster-text-generation/
- DiffusionGemma developer guide: https://developers.googleblog.com/diffusiongemma-the-developer-guide/
- gpt-oss (OpenAI official): https://openai.com/index/introducing-gpt-oss/
- Nemotron 3 Super (Unsloth): https://unsloth.ai/docs/models/nemotron-3/nemotron-3-super
- Nemotron 3 Nano Omni (Unsloth): https://unsloth.ai/docs/models/nemotron-3-nano-omni
- Nemotron 3 Nano vLLM cookbook (NVIDIA): https://github.com/NVIDIA-NeMo/Nemotron
- Mistral Small 4 (Mistral official): https://mistral.ai/news/mistral-small-4/
- Mistral Small 4 VRAM: https://willitrunai.com/blog/mistral-small-4-vram-requirements
- Cosmos 3 (NVIDIA newsroom): https://nvidianews.nvidia.com/news/nvidia-launches-cosmos-3-the-open-frontier-foundation-model-for-physical-ai
- Cosmos 3 (Hugging Face): https://huggingface.co/blog/nvidia/cosmos-3-for-physical-ai

---

*Lưu ý: Số VRAM là ước lượng weights-only; cần cộng thêm KV cache + overhead runtime tùy context length và batch size. Benchmark lấy từ công bố chính thức của vendor hoặc báo cáo cộng đồng tại thời điểm 06/2026 — nên verify lại trên model card trước khi deploy production.*