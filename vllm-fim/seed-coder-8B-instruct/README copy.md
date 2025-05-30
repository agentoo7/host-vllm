# Run test api

```bash
curl http://192.168.59.54:6002/v1/completions \
  -X POST \
  -H "Authorization: Bearer fim-apikey" \
  -H "Content-Type: application/json" \
  -d '{
        "model": "ByteDance-Seed/Seed-Coder-8B-Instruct",
        "prompt": "def fibonacy():",
        "temperature": 0.7,
        "max_tokens": 100
      }'

```

vllm serve \
  "deepseek-ai/deepseek-coder-6.7b-instruct" \
  --tensor_parallel_size 2 \
  --port 9876


