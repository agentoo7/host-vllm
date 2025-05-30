

# Evaluate

```bash

lm_eval --model local-completions \
  --tasks hellaswag \
  --output_path ./results \
  --log_samples \
  --model_args model=Qwen/Qwen3-30B-A3B,base_url=http://localhost:6005/v1/completions,num_concurrent=8,max_retries=3,timeout=3000,seed=1234,temperature=0

```

## Result

- executed time: 23:34
   - Requesting API: 100%|█████████████████| 40168/40168 [23:34<00:00, 28.40it/s]

- table of result 

|  Tasks  |Version|Filter|n-shot| Metric |   |Value |   |Stderr|
|---------|------:|------|-----:|--------|---|-----:|---|-----:|
|hellaswag|      1|none  |     0|acc     |↑  |0.5960|±  |0.0049|
|         |       |none  |     0|acc_norm|↑  |0.7766|±  |0.0042|