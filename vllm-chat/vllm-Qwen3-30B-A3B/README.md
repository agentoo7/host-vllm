# Run test api

```bash
curl http://192.168.59.54:6001/v1/chat/completions  \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer chat-apikey" \
     -d '{
         "model": "Qwen/Qwen3-30B-A3B",
         "messages": [
             {"role": "system", "content": "You are a helpful assistant."},
             {"role": "user", "content": "What is the capital of France?"},
             {"role": "assistant", "content": "The capital of France is Paris."},
             {"role": "user", "content": "Can you tell me more about Paris?"}
         ],
         "temperature": 0.7,
         "max_tokens": 100
     }'


curl http://192.168.59.54:6001/v1/chat/completions  \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer chat-apikey" \
     -d '{
         "model": "Qwen/Qwen3-30B-A3B",
         "messages": [
             {"role": "system", "content": "/no_think You are a helpful assistant."},
             {"role": "user", "content": "1+10="}
         ],
         "temperature": 0.7,
         "max_tokens": 1000 
     }'

```

# Evaluate

```bash

lm_eval --model local-completions \
  --tasks hellaswag \
  --output_path ./results \
  --log_samples \
  --model_args model=Qwen/Qwen3-30B-A3B,base_url=http://localhost:6001/v1/completions,num_concurrent=8,max_retries=3,timeout=3000,seed=1234,temperature=0

```

## Result

- executed time: 23:34
   - Requesting API: 100%|█████████████████| 40168/40168 [23:34<00:00, 28.40it/s]

- table of result 

|  Tasks  |Version|Filter|n-shot| Metric |   |Value |   |Stderr|
|---------|------:|------|-----:|--------|---|-----:|---|-----:|
|hellaswag|      1|none  |     0|acc     |↑  |0.5960|±  |0.0049|
|         |       |none  |     0|acc_norm|↑  |0.7766|±  |0.0042|