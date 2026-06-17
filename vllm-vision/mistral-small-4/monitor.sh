#!/bin/bash
# Track the weights download for this model and auto-restart the container on a stall.
# Usage: ./monitor.sh [interval_seconds]   (default 30)
set -u

MODEL_DIR="$HOME/.cache/huggingface/hub/models--mistralai--Mistral-Small-4-119B-2603-NVFP4"
TARGET_GB=62                                   # approximate final NVFP4 size
CONTAINER="Mistral-Small-4-119B-2603-NVFP4"    # container_name in docker-compose.yml

COMPOSE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL=${1:-30}
HEALTH_URL="http://localhost:20012/v1/models"
stall_count=0
prev_total=""

while true; do
    total=$(du -sb "$MODEL_DIR" 2>/dev/null | cut -f1); total=${total:-0}
    total_gb=$(echo "scale=1; $total/1073741824" | bc)
    remaining=$(echo "$TARGET_GB - $total_gb" | bc)
    pct=$(echo "scale=0; $total_gb*100/$TARGET_GB" | bc)

    if [ -n "$prev_total" ]; then
        diff=$(echo "$total - $prev_total" | bc)
        speed_mbs=$(echo "scale=1; $diff/1048576/$INTERVAL" | bc)
        if [ "$(echo "$diff > 0" | bc)" -eq 1 ]; then
            eta_min=$(echo "scale=1; ($TARGET_GB - $total_gb)*1024/$speed_mbs/60" | bc 2>/dev/null)
        else
            eta_min="stalled"
        fi
    else
        speed_mbs="..."; eta_min="calculating"
    fi
    prev_total=$total
    ts=$(date '+%H:%M:%S')

    if [ "$(echo "$remaining <= 0" | bc)" -eq 1 ]; then
        echo "[$ts] ${total_gb}GB/${TARGET_GB}GB (100%) | DOWNLOAD COMPLETE"
        curl -s -o /dev/null -H "Authorization: Bearer lvm-apikey" "$HEALTH_URL" && echo "[$ts] server is UP"
        break
    fi

    echo "[$ts] ${total_gb}GB/${TARGET_GB}GB (${pct}%) | speed: ${speed_mbs}MB/s | ETA: ~${eta_min}min"

    if ! docker ps --filter "name=$CONTAINER" --format '{{.Status}}' | grep -q Up; then
        echo "[$ts] WARNING: container $CONTAINER is not running"
    fi

    # Two consecutive 0 MB/s ticks → restart the container to kick the download.
    if [ "$speed_mbs" != "..." ] && [ "$(echo "$speed_mbs == 0" | bc)" -eq 1 ]; then
        stall_count=$((stall_count + 1))
        echo "[$ts] WARNING: download stalled (0 MB/s) [${stall_count}/2]"
        if [ "$stall_count" -ge 2 ]; then
            echo "[$ts] auto-restarting container..."
            (cd "$COMPOSE_DIR" && docker compose restart) 2>&1
            stall_count=0; sleep 30
        fi
    else
        stall_count=0
    fi

    sleep "$INTERVAL"
done
