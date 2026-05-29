# Set biến cho gọn
export EMB="http://192.168.59.54:60013"
export KEY="embed-apikey"

# 1. Verify model loaded
curl -s "$EMB/v1/models" \
  -H "Authorization: Bearer $KEY" | jq

# 2. Health check (thường không cần auth)
curl -s "$EMB/health"

# 3. Basic embedding — single input
curl -s "$EMB/v1/embeddings" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-m3",
    "input": "luồng xác thực người dùng hoạt động ra sao?"
  }' | jq '{
    model: .model,
    dim: (.data[0].embedding | length),
    first_5: .data[0].embedding[0:5],
    tokens: .usage.prompt_tokens
  }'

# 4. Batch embedding
curl -s "$EMB/v1/embeddings" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-m3",
    "input": [
      "luồng xác thực người dùng",
      "user authentication flow",
      "用户认证流程",
      "ユーザー認証フロー",
      "thanh toán qua thẻ tín dụng"
    ]
  }' | jq '{
    count: (.data | length),
    dim: (.data[0].embedding | length),
    total_tokens: .usage.total_tokens
  }'

# 5. Cross-lingual similarity
curl -s "$EMB/v1/embeddings" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "BAAI/bge-m3",
    "input": [
      "luồng xác thực người dùng",
      "user authentication flow",
      "thanh toán qua thẻ tín dụng"
    ]
  }'