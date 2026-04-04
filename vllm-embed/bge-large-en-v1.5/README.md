# Run test api

```bash
curl -X 'POST' \
  'http://0.0.0.0:60010/v1/embeddings' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer embed-apikey" \
  -d '{
  "model": "BAAI/bge-large-en-v1.5",
  "input": [
    "def calculate(a:int)->int"

  ],
  "encoding_format": "float",
  "user": "string",
  "truncate_prompt_tokens": 1,
  "additional_data": "string",
  "add_special_tokens": true,
  "priority": 0,
  "additionalProp1": {}
}'

```


