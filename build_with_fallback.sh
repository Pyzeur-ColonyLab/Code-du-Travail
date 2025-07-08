#!/bin/bash

echo "[INFO] Comprehensive Docker Build with Fallback Options"
echo "[STEP] Attempting build with main Dockerfile..."

# Try main Dockerfile first
if docker-compose build --no-cache telegram-bot; then
    echo "[SUCCESS] Build completed with main Dockerfile!"
    exit 0
fi

echo "[WARNING] Main Dockerfile failed, trying alternative Dockerfile..."

# Try alternative Dockerfile
cp Dockerfile Dockerfile.backup
cp Dockerfile.alternative Dockerfile

if docker-compose build --no-cache telegram-bot; then
    echo "[SUCCESS] Build completed with alternative Dockerfile!"
    mv Dockerfile.backup Dockerfile
    exit 0
fi

echo "[WARNING] Alternative Dockerfile failed, trying fallback Dockerfile..."

# Try fallback Dockerfile (no system dependencies)
cp Dockerfile Dockerfile.alternative.backup
cp Dockerfile.fallback Dockerfile

if docker-compose build --no-cache telegram-bot; then
    echo "[SUCCESS] Build completed with fallback Dockerfile!"
    mv Dockerfile.backup Dockerfile
    mv Dockerfile.alternative.backup Dockerfile.alternative
    exit 0
fi

echo "[ERROR] All Dockerfile options failed!"
echo "[INFO] Restoring original Dockerfile..."
mv Dockerfile.backup Dockerfile
mv Dockerfile.alternative.backup Dockerfile.alternative

echo "[INFO] Please run the DNS fix script first:"
echo "chmod +x fix_ubuntu_dns.sh"
echo "./fix_ubuntu_dns.sh"
exit 1 