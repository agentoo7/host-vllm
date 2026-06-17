#!/bin/bash
# Quick smoke tests for Gemma 4 12B (audio-capable) on http://localhost:20012
set -e
BASE="http://localhost:20012"
KEY="lvm-apikey"
MODEL="google/gemma-4-12B-it"

echo "== 1. list models =="
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" | python3 -m json.tool

echo "== 2. text chat =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Summarize Romeo and Juliet in 3 sentences.\"}],\"max_tokens\":200}" \
  | python3 -m json.tool

echo "== 3. image (remote URL) =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image.\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"http://images.cocodataset.org/val2017/000000039769.jpg\"}}]}],\"max_tokens\":200}" \
  | python3 -m json.tool

# == 4. audio (local file) — drop a 16kHz ./data/speech.wav first, then uncomment ==
# curl -s "$BASE/v1/chat/completions" \
#   -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
#   -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Transcribe this audio.\"},{\"type\":\"audio_url\",\"audio_url\":{\"url\":\"file:///data/speech.wav\"}}]}],\"max_tokens\":256}" \
#   | python3 -m json.tool
