#!/bin/bash
# Quick smoke tests for gpt-oss-120b on http://localhost:20012
set -e
BASE="http://localhost:20012"
KEY="lvm-apikey"
MODEL="openai/gpt-oss-120b"

echo "== 1. list models =="
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" | python3 -m json.tool

echo "== 2. reasoning chat =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"A train travels 60 km in 45 minutes. Average speed in km/h? Show reasoning.\"}],\"max_tokens\":400}" \
  | python3 -m json.tool

echo "== 3. tool calling =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"What is the weather in San Francisco?\"}],\"tools\":[{\"type\":\"function\",\"function\":{\"name\":\"get_weather\",\"description\":\"Get current weather\",\"parameters\":{\"type\":\"object\",\"properties\":{\"location\":{\"type\":\"string\"}},\"required\":[\"location\"]}}}],\"tool_choice\":\"auto\"}" \
  | python3 -m json.tool
