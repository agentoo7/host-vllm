# Run test api

```bash
curl http://0.0.0.0:6002/v1/completions \
  -X POST \
  -H "Authorization: Bearer fim-apikey" \
  -H "Content-Type: application/json" \
  -d '{
        "model": "Gen-Verse/ReasonFlux-Coder-7B",
        "prompt": "def fibonacy():",
        "temperature": 0.7,
        "max_tokens": 100
      }'

```


```bash
curl http://0.0.0.0:6002/v1/chat/completions  \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer fim-apikey" \
     -d '{
         "model": "Gen-Verse/ReasonFlux-Coder-7B",
         "messages": [
             {"role": "system", "content": "You are a helpful coding assistant."},
             {"role": "user", "content": "def fibonacy():"}
         ],
         "temperature": 0.7,
         "max_tokens": 100
     }'
```


