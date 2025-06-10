#!/bin/bash

# Setup script for Code du Travail Telegram Bot on AWS EC2

set -e

echo "🚀 Setting up Code du Travail Telegram Bot..."

# Detect OS
if [ -f /etc/redhat-release ] || [ -f /etc/amazon-linux-release ]; then
    OS="amazon"
    PKG_MANAGER="yum"
elif [ -f /etc/debian_version ]; then
    OS="debian"
    PKG_MANAGER="apt"
else
    echo "Unsupported OS"
    exit 1
fi

echo "📦 Detected OS: $OS"

# Update system
echo "📦 Updating system packages..."
if [ "$OS" = "amazon" ]; then
    sudo yum update -y
    sudo yum install -y python3-devel gcc gcc-c++ make tmux git wget curl htop
    sudo yum groupinstall -y "Development Tools"
else
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y python3 python3-pip python3-venv git wget curl htop tmux build-essential
fi

# Install/upgrade pip
echo "🐍 Setting up Python environment..."
python3 -m ensurepip --upgrade 2>/dev/null || true
python3 -m pip install --upgrade pip

# Install virtualenv if not available
python3 -m pip install virtualenv

# Create virtual environment
echo "🐍 Creating Python virtual environment..."
if [ -d "venv" ]; then
    rm -rf venv
fi
python3 -m virtualenv venv
source venv/bin/activate

# Upgrade pip in venv
pip install --upgrade pip

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip install -r requirements.txt

# Create logs directory
mkdir -p logs

# Set up environment file
echo "⚙️ Setting up environment configuration..."
if [ ! -f .env ]; then
    cp .env.example .env
    echo "📝 Please edit .env file and add your TELEGRAM_BOT_TOKEN"
    echo "   You can edit it with: vi .env (or nano .env if available)"
fi

# Make scripts executable
chmod +x *.sh *.py

# Create systemd service for Amazon Linux
if [ "$OS" = "amazon" ]; then
    echo "🔧 Creating systemd service..."
    sudo cp code-du-travail-bot.service /etc/systemd/system/
    sudo sed -i "s|/home/ubuntu|$HOME|g" /etc/systemd/system/code-du-travail-bot.service
    sudo sed -i "s|User=ubuntu|User=$USER|g" /etc/systemd/system/code-du-travail-bot.service
    sudo sed -i "s|Group=ubuntu|Group=$USER|g" /etc/systemd/system/code-du-travail-bot.service
    sudo systemctl daemon-reload
    sudo systemctl enable code-du-travail-bot.service
fi

echo "✅ Setup completed!"
echo ""
echo "📋 Next steps:"
echo "1. Edit .env file and add your TELEGRAM_BOT_TOKEN:"
echo "   vi .env"
echo ""
echo "2. Test the bot:"
echo "   source venv/bin/activate"
echo "   python run.py --check"
echo ""
echo "3. Start the bot:"
echo "   ./start_bot.sh --background"
echo ""
echo "4. Check status:"
echo "   ./status_bot.sh"
echo ""
echo "5. View logs:"
echo "   tail -f bot.log"