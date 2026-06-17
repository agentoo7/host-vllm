#!/bin/bash
# Quick smoke tests for Mistral Small 4 (NVFP4) on http://localhost:20012
set -e
BASE="http://localhost:20012"
KEY="lvm-apikey"
MODEL="mistralai/Mistral-Small-4-119B-2603-NVFP4"

echo "== 1. list models =="
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" | python3 -m json.tool

echo "== 2. text chat =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Write a haiku about GPUs.\"}],\"max_tokens\":128}" \
  | python3 -m json.tool

echo "== 3. image (remote URL) =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image.\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"http://images.cocodataset.org/val2017/000000039769.jpg\"}}]}],\"max_tokens\":200}" \
  | python3 -m json.tool
