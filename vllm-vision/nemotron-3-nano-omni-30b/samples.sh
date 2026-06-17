#!/bin/bash
# Quick smoke tests for Nemotron 3 Nano Omni 30B on http://localhost:20012
set -e
BASE="http://localhost:20012"
KEY="lvm-apikey"
MODEL="nvidia/Nemotron-3-Nano-Omni-30B-A3B-Reasoning-FP8"

echo "== 1. list models =="
curl -s "$BASE/v1/models" -H "Authorization: Bearer $KEY" | python3 -m json.tool

echo "== 2. text reasoning =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"If 5 machines make 5 widgets in 5 min, how long for 100 machines to make 100 widgets? Reason step by step.\"}],\"max_tokens\":400}" \
  | python3 -m json.tool

echo "== 3. image (remote URL) =="
curl -s "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Describe this image.\"},{\"type\":\"image_url\",\"image_url\":{\"url\":\"http://images.cocodataset.org/val2017/000000039769.jpg\"}}]}],\"max_tokens\":200}" \
  | python3 -m json.tool

# == 4. video / 5. audio — drop ./data/clip.mp4 or ./data/speech.wav first, then uncomment ==
# curl -s "$BASE/v1/chat/completions" \
#   -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
#   -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":[{\"type\":\"text\",\"text\":\"Summarize this video.\"},{\"type\":\"video_url\",\"video_url\":{\"url\":\"file:///data/clip.mp4\"}}]}],\"max_tokens\":400}" \
#   | python3 -m json.tool
