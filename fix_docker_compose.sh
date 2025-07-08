#!/bin/bash
set -e
echo "Fixing Docker Compose compatibility issue..."
echo "Stopping and removing existing containers..."
docker-compose down --remove-orphans
docker system prune -f
echo "Updating Docker Compose..."
sudo apt update
sudo apt install -y docker-compose-plugin
echo "Docker Compose fix completed!"
