#!/bin/bash

# CPU-only startup script for Code du Travail AI Assistant
# This script forces CPU mode and uses optimized settings for CPU-only instances

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_info "Code du Travail AI Assistant - CPU Mode"
print_info "======================================"

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_error ".env file not found!"
    print_info "Please copy the example file and configure it:"
    print_info "cp .env.example .env"
    print_info "nano .env"
    exit 1
fi

# Check Docker Compose
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    print_error "Docker Compose not found. Please install Docker Compose."
    exit 1
fi

# Force CPU mode
print_step "Forcing CPU mode..."
export DEVICE=cpu
export USE_QUANTIZATION=true
export LOAD_IN_4BIT=true

# Create directories
print_step "Creating directories..."
mkdir -p docker-data/dms/config
mkdir -p docker-data/dms/mail-data
mkdir -p docker-data/dms/mail-state
mkdir -p docker-data/dms/mail-logs
mkdir -p logs

# Stop any existing containers
print_step "Stopping existing containers..."
$DOCKER_COMPOSE_CMD -f docker-compose.cpu.yml down 2>/dev/null || true

# Start services with CPU configuration
print_step "Starting services with CPU optimization..."
$DOCKER_COMPOSE_CMD -f docker-compose.cpu.yml up -d

# Wait for services to start
print_step "Waiting for services to start..."
sleep 10

# Show status
print_step "Service status:"
$DOCKER_COMPOSE_CMD -f docker-compose.cpu.yml ps

print_info "✅ Services started successfully!"
print_info ""
print_info "Next steps:"
print_info "1. Check logs: $DOCKER_COMPOSE_CMD -f docker-compose.cpu.yml logs -f"
print_info "2. Setup email accounts: ./start_mailserver_bot.sh setup"
print_info "3. Test the bot by sending a message to your Telegram bot"
print_info ""
print_info "CPU Mode Features:"
print_info "- 4-bit quantization for memory efficiency"
print_info "- Reduced token limits for faster responses"
print_info "- Optimized resource allocation"
print_info "- No GPU dependencies" 