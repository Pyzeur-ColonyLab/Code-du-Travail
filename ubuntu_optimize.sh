#!/bin/bash
set -e
echo "Ubuntu 22.04 Optimization for Code du Travail AI Assistant"
echo "========================================================="
echo "Configuring Docker DNS..."
sudo mkdir -p /etc/docker
sudo systemctl restart docker
echo "Setting proper permissions..."
chmod +x *.sh
echo "Ubuntu 22.04 optimization completed!"
