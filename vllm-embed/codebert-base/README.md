# Run test api

```bash
curl -X 'POST' \
  'http://192.168.59.54:6003/v1/embeddings' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer embed-apikey" \
  -d '{
  "model": "microsoft/codebert-base",
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


