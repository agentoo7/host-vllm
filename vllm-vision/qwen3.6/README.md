# Qwen3.5-27B Claude 4.6 Opus Reasoning Distilled (AWQ)

Host [QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ](https://huggingface.co/QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ) via vLLM with OpenAI-compatible API.

## Quick Start

```bash
docker compose up -d
```

- **Port:** `20012`
- **GPU:** 2x NVIDIA GPU
- **Max context:** 262144 tokens
- **Features:** prefix caching, auto tool choice, reasoning parser

## API Examples

### Vision - Describe Image

```bash
curl -X POST "http://192.168.59.54:20012/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer lvm-apikey" \
  --data '{
    "model": "QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Describe this image in one sentence."
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "https://cdn.britannica.com/61/93061-050-99147DCE/Statue-of-Liberty-Island-New-York-Bay.jpg"
            }
          }
        ]
      }
    ]
  }'
```

### Vision - OCR / Extract Text

```bash
curl -X POST "http://localhost:20012/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer lvm-apikey" \
  --data '{
    "model": "QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ",
    "messages": [
      {
        "role": "user",
        "content": [
          {
            "type": "text",
            "text": "Extract text from this image."
          },
          {
            "type": "image_url",
            "image_url": {
              "url": "https://costpocket.com/img/create/images/XddH0-unnamed(4).png"
            }
          }
        ]
      }
    ]
  }'
```

### Tool Calling

```bash
curl -X POST "http://localhost:20012/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer lvm-apikey" \
  --data '{
    "model": "QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ",
    "messages": [
      {
        "role": "user",
        "content": "What is the weather in San Francisco today?"
      }
    ],
    "tools": [
      {
        "type": "function",
        "function": {
          "name": "get_weather",
          "description": "Get the current weather in a given location",
          "parameters": {
            "type": "object",
            "properties": {
              "location": {
                "type": "string",
                "description": "The city and state, e.g. San Francisco, CA"
              },
              "unit": {
                "type": "string",
                "enum": ["celsius", "fahrenheit"],
                "description": "The temperature unit"
              }
            },
            "required": ["location"]
          }
        }
      }
    ],
    "tool_choice": "auto"
  }'
```

## Using with Claude Code

```bash
export ANTHROPIC_BASE_URL="http://192.168.59.54:20012"
export ANTHROPIC_API_KEY="dummy"
export ANTHROPIC_DEFAULT_OPUS_MODEL="QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ"
export ANTHROPIC_DEFAULT_SONNET_MODEL="QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="QuantTrio/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-v2-AWQ"
claude
```
