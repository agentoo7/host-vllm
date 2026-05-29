#!/bin/bash
MODEL_DIR="$HOME/.cache/huggingface/hub/models--Jackrong--Qwen3.5-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled"
TARGET_GB=65
INTERVAL=${1:-30}
stall_count=0

while true; do
    total=$(du -sb "$MODEL_DIR/" 2>/dev/null | cut -f1)
    total_gb=$(echo "scale=1; $total/1073741824" | bc)
    inc=$(ls -lh "$MODEL_DIR/blobs/"*.incomplete 2>/dev/null | awk '{print $5}')
    completed=$(ls "$MODEL_DIR/blobs/" 2>/dev/null | grep -cv incomplete)
    remaining=$(echo "$TARGET_GB - $total_gb" | bc)
    pct=$(echo "scale=0; $total_gb*100/$TARGET_GB" | bc)

    # Calculate speed from last check
    if [ -n "$prev_total" ]; then
        diff=$(echo "$total - $prev_total" | bc)
        speed_mbs=$(echo "scale=1; $diff/1048576/$INTERVAL" | bc)
        if [ "$(echo "$speed_mbs > 0" | bc)" -eq 1 ]; then
            eta_sec=$(echo "scale=0; $remaining*1073741824/$diff*$INTERVAL" | bc 2>/dev/null)
            eta_min=$(echo "scale=1; $eta_sec/60" | bc 2>/dev/null)
        else
            eta_min="stalled"
        fi
    else
        speed_mbs="..."
        eta_min="calculating"
    fi
    prev_total=$total

    timestamp=$(date '+%H:%M:%S')

    if [ "$(echo "$remaining <= 0" | bc)" -eq 1 ]; then
        echo "[$timestamp] ${total_gb}GB/${TARGET_GB}GB (100%) | ${completed} files | DOWNLOAD COMPLETE!"
        # Check if vllm is serving
        if curl -s http://localhost:8000/health >/dev/null 2>&1; then
            echo "[$timestamp] vLLM server is UP and healthy!"
        fi
        break
    fi

    echo "[$timestamp] ${total_gb}GB/${TARGET_GB}GB (${pct}%) | ${completed} files done | downloading: ${inc:-none} | speed: ${speed_mbs}MB/s | ETA: ~${eta_min}min"

    # Check if container is still running
    if ! docker ps --filter name=vllm-qwen-397b --format "{{.Status}}" | grep -q "Up"; then
        echo "[$timestamp] WARNING: Container is not running!"
    fi

    # Check for network stall and auto-restart
    if [ "$speed_mbs" != "..." ] && [ "$(echo "$speed_mbs == 0" | bc)" -eq 1 ]; then
        stall_count=$((stall_count + 1))
        echo "[$timestamp] WARNING: Download stalled (0 MB/s) [${stall_count}/2]"
        if [ "$stall_count" -ge 2 ]; then
            echo "[$timestamp] Auto-restarting container..."
            cd /home/binhtran/work/dev/vllm-hosting/vllm-vision/qwen3.5 && docker compose restart 2>&1
            stall_count=0
            echo "[$timestamp] Container restarted. Waiting 30s for download to resume..."
            sleep 30
        fi
    else
        stall_count=0
    fi

    sleep "$INTERVAL"
done
