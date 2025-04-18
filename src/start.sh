#!/usr/bin/env bash

# --- ЛОГИРОВАНИЕ --- #
LOG_FILE="/comfyui/models/startup.log"
mkdir -p /comfyui/models
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========== Запуск start.sh: $(date) =========="

# --- ДОБАВЛЕНО: Символические ссылки на папки из RunPod тома --- #

echo "Создаём симлинки на модели..."
rm -rf /comfyui/models && ln -s /runpod-volume/ComfyUI/models /comfyui/models

echo "Создаём симлинки на custom_nodes..."
rm -rf /comfyui/custom_nodes && ln -s /runpod-volume/ComfyUI/custom_nodes /comfyui/custom_nodes

echo "Создаём симлинки на input..."
rm -rf /comfyui/input && ln -s /runpod-volume/ComfyUI/input /comfyui/input

echo "Создаём симлинки на output..."
rm -rf /comfyui/output && ln -s /runpod-volume/ComfyUI/output /comfyui/output

# --- КОНЕЦ ДОБАВЛЕНИЯ --- #

echo "Поиск libtcmalloc для оптимизации памяти..."
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
echo "Используется: ${TCMALLOC}"

# Serve the API and don't shutdown the container
if [ "$SERVE_API_LOCALLY" == "true" ]; then
    echo "Режим локального запуска API: true"
    echo "Запуск ComfyUI..."
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata --listen &
    
    echo "Запуск RunPod Handler..."
    python3 -u /rp_handler.py --rp_serve_api --rp_api_host=0.0.0.0
else
    echo "Режим локального запуска API: false"
    echo "Запуск ComfyUI..."
    python3 /comfyui/main.py --disable-auto-launch --disable-metadata &
    
    echo "Запуск RunPod Handler..."
    python3 -u /rp_handler.py
fi
