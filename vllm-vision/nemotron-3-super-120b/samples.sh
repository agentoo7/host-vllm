#!/bin/bash
# Quick smoke tests for Nemotron 3 Super 120B (llama.cpp GGUF) on http://localhost:20012
# llama.cpp ignores the "model" field; any string works.
set -e
BASE="http://localhost:20012"
KEY="lvm-apikey"
MODEL="nemotron-super"

echo "== 1. list models =="
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" | python3 -m json.tool

echo "== 2. reasoning chat =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Prove that sqrt(2) is irrational. Reason carefully.\"}],\"max_tokens\":600,\"temperature\":1.0,\"top_p\":0.95}" \
  | python3 -m json.tool
