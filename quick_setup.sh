#!/bin/bash

# Quick Setup Script for Code du Travail AI Assistant
# Download and run this script directly on your Infomaniak instance

set -e

echo "🚀 Quick Setup for Code du Travail AI Assistant"
echo "================================================"
echo

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Update system
echo -e "${BLUE}[STEP]${NC} Updating system..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo -e "${BLUE}[STEP]${NC} Installing essential packages..."
sudo apt install -y curl wget git build-essential python3 python3-pip htop

# Install Docker
echo -e "${BLUE}[STEP]${NC} Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt install docker-compose-plugin -y
sudo usermod -aG docker $USER

# Clone repository
echo -e "${BLUE}[STEP]${NC} Cloning repository..."
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail

# Make scripts executable
chmod +x *.sh

# Run interactive setup
echo -e "${BLUE}[STEP]${NC} Starting interactive setup..."
./interactive_setup.sh

echo
echo -e "${GREEN}✅ Setup completed!${NC}"
echo
echo "Next steps:"
echo "1. Logout and login again for Docker group changes"
echo "2. Check status: ./start_mailserver_bot.sh status"
echo "3. View logs: ./start_mailserver_bot.sh logs"
echo
echo "Your Code du Travail AI Assistant is ready! 🎉" 