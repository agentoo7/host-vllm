pip install autoawq

python -c "
from awq import AutoAWQForCausalLM
from transformers import AutoTokenizer

model_path = 'Jackrong/Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled'
output_path = './qwen35-35b-distilled-awq-4bit'

tokenizer = AutoTokenizer.from_pretrained(model_path)
model = AutoAWQForCausalLM.from_pretrained(model_path, device_map='auto')

quant_config = {
    'zero_point': True,
    'q_group_size': 128,
    'w_bit': 4,
    'version': 'GEMM'
}

model.quantize(tokenizer, quant_config=quant_config)
model.save_quantized(output_path)
tokenizer.save_pretrained(output_path)
print('Done!')
"