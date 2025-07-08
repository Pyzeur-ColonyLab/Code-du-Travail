#!/bin/bash

echo "[INFO] Fixing Docker build issues..."
echo "[STEP] Cleaning Docker system..."

# Stop all containers
docker stop $(docker ps -aq) 2>/dev/null || true

# Remove all containers
docker rm $(docker ps -aq) 2>/dev/null || true

# Remove all images
docker rmi $(docker images -q) 2>/dev/null || true

# Clean Docker system
docker system prune -af

# Clean Docker build cache
docker builder prune -af

echo "[STEP] Rebuilding with clean cache..."
docker-compose build --no-cache

echo "[INFO] Docker build fix completed!" 