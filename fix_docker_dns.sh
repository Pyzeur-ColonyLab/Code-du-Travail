#!/bin/bash

echo "[INFO] Fixing Docker DNS issues..."
echo "[STEP] Configuring Docker daemon DNS settings..."

# Create Docker daemon configuration directory
sudo mkdir -p /etc/docker

# Create or update Docker daemon configuration
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["8.8.8.8", "8.8.4.4", "1.1.1.1"],
  "dns-opts": ["timeout:2", "attempts:3"],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

echo "[STEP] Restarting Docker daemon..."
sudo systemctl restart docker

echo "[STEP] Waiting for Docker to be ready..."
sleep 5

echo "[STEP] Testing Docker DNS resolution..."
docker run --rm alpine nslookup deb.debian.org

echo "[STEP] Cleaning Docker system..."
docker system prune -af

echo "[INFO] Docker DNS fix completed!"
echo "[INFO] You can now try building again with: docker-compose build --no-cache" 