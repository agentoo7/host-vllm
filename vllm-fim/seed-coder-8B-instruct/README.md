# Run test api

```bash
curl http://0.0.0.0:6002/v1/completions \
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


