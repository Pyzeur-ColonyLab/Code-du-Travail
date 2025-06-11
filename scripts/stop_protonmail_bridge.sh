#!/bin/bash

# ProtonMail Bridge Stop Script
# Stops all ProtonMail Bridge processes cleanly

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

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

mkdir -p logs

log "Stopping ProtonMail Bridge..."

# Check if bridge is running
if pgrep -f protonmail-bridge > /dev/null; then
    log "Found running ProtonMail Bridge processes:"
    ps aux | grep protonmail-bridge | grep -v grep | tee -a "$LOG_FILE"
    
    # Stop bridge processes
    log "Stopping ProtonMail Bridge processes..."
    pkill -TERM -f protonmail-bridge || true
    sleep 3
    
    # Force kill if still running
    if pgrep -f protonmail-bridge > /dev/null; then
        warning "Bridge still running, force killing..."
        pkill -KILL -f protonmail-bridge || true
        sleep 2
    fi
    
    # Check if stopped
    if ! pgrep -f protonmail-bridge > /dev/null; then
        success "ProtonMail Bridge stopped successfully"
    else
        warning "Some bridge processes may still be running"
    fi
else
    log "ProtonMail Bridge is not running"
fi

# Stop virtual display if running
if pgrep -f "Xvfb :99" > /dev/null; then
    log "Stopping virtual display..."
    pkill -f "Xvfb :99" || true
    success "Virtual display stopped"
fi

# Remove lock files
LOCK_FILE="$HOME/.config/protonmail/bridge/bridge.lock"
if [ -f "$LOCK_FILE" ]; then
    log "Removing lock file: $LOCK_FILE"
    rm -f "$LOCK_FILE"
fi

log "ProtonMail Bridge cleanup completed"
echo "✅ ProtonMail Bridge stopped and cleaned up"
