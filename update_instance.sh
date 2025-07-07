#!/bin/bash

# Update script for Code du Travail AI Assistant instance
# This script pulls the latest changes from GitHub and restarts services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Configuration - Use current directory or HOME
PROJECT_DIR="${PWD:-$HOME/Code-du-Travail}"
GITHUB_REPO="https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git"

print_info "Code du Travail AI Assistant - Instance Update"
print_info "============================================="

# Check if we're in the right directory
if [ ! -d ".git" ]; then
    print_error "Not a git repository. Please run this script from the Code-du-Travail directory."
    print_info "Current directory: $PWD"
    exit 1
fi

print_info "Using project directory: $PWD"

# Stop services before updating
print_step "Stopping services..."
if [ -f "start_mailserver_bot.sh" ]; then
    ./start_mailserver_bot.sh stop
fi

# Pull latest changes
print_step "Pulling latest changes from GitHub..."
git fetch origin
git reset --hard origin/main

# Make scripts executable
print_step "Making scripts executable..."
chmod +x start_mailserver_bot.sh
chmod +x setup_mailserver.sh
chmod +x deploy_infomaniak.sh
chmod +x update_instance.sh

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Please create one with your configuration."
    print_info "You can copy from .env.example if available."
fi

# Restart services
print_step "Restarting services..."
if [ -f "start_mailserver_bot.sh" ]; then
    ./start_mailserver_bot.sh start
fi

print_info "Update completed successfully!"
print_info "You can check the status with: ./start_mailserver_bot.sh status"
print_info "View logs with: ./start_mailserver_bot.sh logs"
