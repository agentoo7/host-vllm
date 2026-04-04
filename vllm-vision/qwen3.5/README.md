curl -X POST "http://192.168.59.54:20012/v1/chat/completions" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer lvm-apikey" \
	--data '{
		"model": "codgician/Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-GPTQ-int4",
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



curl -X POST "http://localhost:20012/v1/chat/completions" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer lvm-apikey" \
	--data '{
		"model": "codgician/Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-GPTQ-int4",
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