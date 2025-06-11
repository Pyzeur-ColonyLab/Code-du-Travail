#!/bin/bash

# ProtonMail Bridge Startup Script
# Starts bridge in headless mode with virtual display

set -e

LOG_FILE="logs/protonmail_bridge.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

mkdir -p logs

log "Starting ProtonMail Bridge..."

# Check if bridge is installed
if ! command -v protonmail-bridge &> /dev/null; then
    error "ProtonMail Bridge is not installed. Run ./scripts/install_protonmail_bridge.sh first"
fi

# Check if bridge is already running
if pgrep -f protonmail-bridge > /dev/null; then
    warning "ProtonMail Bridge is already running"
    ps aux | grep protonmail-bridge | grep -v grep
    log "IMAP: localhost:1143, SMTP: localhost:1025"
    exit 0
fi

# Set environment for headless mode
export DISPLAY=:99
export QT_QPA_PLATFORM=offscreen

# Start virtual display if not running
if ! pgrep -f "Xvfb :99" > /dev/null; then
    log "Starting virtual display..."
    Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
    sleep 2
    success "Virtual display started"
fi

# Start ProtonMail Bridge in background
log "Starting ProtonMail Bridge in headless mode..."
protonmail-bridge --noninteractive --log-level info >> "$LOG_FILE" 2>&1 &

# Wait a moment for startup
sleep 5

# Check if bridge started successfully
if pgrep -f protonmail-bridge > /dev/null; then
    success "ProtonMail Bridge started successfully!"
    
    # Display connection info
    echo ""
    echo "🎉 ProtonMail Bridge is running!"
    echo "📧 IMAP: localhost:1143 (with STARTTLS)"
    echo "📤 SMTP: localhost:1025 (with STARTTLS)"
    echo "📋 Logs: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Login to your ProtonMail account: protonmail-bridge --cli"
    echo "2. Get bridge password and update .env file"
    echo "3. Test connection: ./scripts/test_protonmail_connection.sh"
    
    # Check if ports are listening
    sleep 2
    if netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null; then
        success "IMAP port 1143 is listening"
    else
        warning "IMAP port 1143 not yet available"
    fi
    
    if netstat -tlnp 2>/dev/null | grep ":1025 " > /dev/null; then
        success "SMTP port 1025 is listening"
    else
        warning "SMTP port 1025 not yet available"
    fi
    
else
    error "Failed to start ProtonMail Bridge. Check logs: $LOG_FILE"
fi

log "Bridge startup completed"
