
source .env



# ******* CHAT ***************

# gpu_memory_utilization=0.7 \
# HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN \
# port=6001 \
# docker compose -f "vllm-chat/vllm-Qwen3-30B-A3B/docker-compose.yml" up -d


#******* FIM ***************

# gpu_memory_utilization=0.965 \
# HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN \
# port=6002 \
# docker compose -f "vllm-fim/seed-coder-8B-instruct/docker-compose.yml" up -d
#-------------------------------

# ******* EMBED ***************
# gpu_memory_utilization=0.975 \
# port=6003 \
# HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN \
# docker compose -f "vllm-embed/codebert-base/docker-compose.yml" up -d



# ******* RE_RANKING ***************
gpu_memory_utilization=0.99 \
port=6004 \
HUGGING_FACE_HUB_TOKEN=$HUGGING_FACE_HUB_TOKEN \
docker compose -f "vllm-re-ranking/bge-reranker-v2-m3/docker-compose.yml" up -d


#**** Auto alocate memory -- Still error ***

# get_average_used_vram() {
#   local total=0 count=0 mem

#   # Sum up used memory (MiB) across all GPUs
#   while read -r mem; do
#     # Strip any stray whitespace
#     mem=${mem//[[:space:]]/}
#     total=$(( total + mem ))
#     count=$(( count + 1 ))
#   done < <(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits)

#   if (( count > 0 )); then
#     # Convert MiB → GB (divide by 1000)
#     echo $(( (total / count) / 1000 ))
#   else
#     echo 0
#   fi
# }

# calculate_percent() {
#     local vram_need=$1
#     used_vram=$(get_average_used_vram)
#     total_vram=$(echo "scale=4; $used_vram + 1.1 * $vram_need" | bc -l)
#     percent=$(echo "scale=4; $total_vram / 46" | bc -l)
#     percent=$(printf "%.2f" "$percent")
#     echo "$percent"
# }





