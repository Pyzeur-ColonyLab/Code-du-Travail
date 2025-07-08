#!/bin/bash
set -e

echo "Debian 11 (Bullseye) Optimization for Code du Travail AI Assistant"
echo "=================================================================="

echo "[STEP] Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "[STEP] Installing essential packages for AI workloads..."
sudo apt install -y \
    htop \
    iotop \
    nload \
    curl \
    wget \
    git \
    build-essential \
    python3-pip \
    python3-venv \
    nvidia-cuda-toolkit \
    nvidia-driver \
    nvidia-settings

echo "[STEP] Configuring Docker DNS..."
sudo mkdir -p /etc/docker
sudo systemctl restart docker

echo "[STEP] Setting proper permissions..."
chmod +x *.sh

echo "[STEP] Optimizing system for AI workloads..."
# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Optimize kernel parameters for AI workloads
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=15" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf

echo "[STEP] Creating swap file if needed..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 4G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo "[INFO] Debian 11 optimization completed!"
echo "[INFO] System is now optimized for AI workloads and Docker containers" 