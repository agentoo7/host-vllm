# Run test api

```bash
curl http://0.0.0.0:6002/v1/completions \
  -X POST \
  -H "Authorization: Bearer fim-apikey" \
  -H "Content-Type: application/json" \
  -d '{
        "model": "bigcode/starcoder2-7b",
        "prompt": "def fibonacy():",
        "temperature": 0.7,
        "max_tokens": 100
      }'

```



