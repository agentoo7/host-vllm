#!/bin/bash
# Quick smoke tests for DiffusionGemma 26B on http://localhost:20012
set -e
BASE="http://localhost:20012"
KEY="lvm-apikey"
MODEL="google/diffusiongemma-26B-A4B-it"

echo "== 1. list models =="
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" | python3 -m json.tool

echo "== 2. text chat =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Write a Python function that reverses a linked list.\"}],\"max_tokens\":200}" \
  | python3 -m json.tool

echo "== 3. code completion =="
curl -s "$BASE/v1/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"prompt\":\"def quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n\",\"max_tokens\":200}" \
  | python3 -m json.tool
