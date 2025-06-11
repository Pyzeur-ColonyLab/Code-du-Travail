#!/bin/bash

# ProtonMail Email Bot Stop Script
# Stops the ProtonMail email bot cleanly

set -e

BOT_NAME="protonmail_email_bot"
LOG_FILE="logs/${BOT_NAME}.log"
PID_FILE="logs/${BOT_NAME}.pid"

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

log "Stopping ProtonMail Email Bot..."

# Check if PID file exists
if [ -f "$PID_FILE" ]; then
    BOT_PID=$(cat "$PID_FILE")
    
    if ps -p "$BOT_PID" > /dev/null 2>&1; then
        log "Found running bot with PID: $BOT_PID"
        
        # Try graceful shutdown first
        log "Sending TERM signal..."
        kill -TERM "$BOT_PID" 2>/dev/null || true
        
        # Wait for graceful shutdown
        for i in {1..10}; do
            if ! ps -p "$BOT_PID" > /dev/null 2>&1; then
                success "Bot stopped gracefully"
                break
            fi
            echo -n "."
            sleep 1
        done
        
        # Force kill if still running
        if ps -p "$BOT_PID" > /dev/null 2>&1; then
            warning "Bot still running, force killing..."
            kill -KILL "$BOT_PID" 2>/dev/null || true
            sleep 2
            
            if ps -p "$BOT_PID" > /dev/null 2>&1; then
                warning "Bot process may still be running"
            else
                success "Bot force stopped"
            fi
        fi
    else
        warning "PID file exists but process not found"
    fi
    
    # Remove PID file
    rm -f "$PID_FILE"
else
    log "No PID file found"
fi

# Check for any remaining processes
REMAINING_PIDS=$(pgrep -f "protonmail_email_bot.py" || true)
if [ -n "$REMAINING_PIDS" ]; then
    warning "Found remaining bot processes: $REMAINING_PIDS"
    echo "Stopping remaining processes..."
    
    for pid in $REMAINING_PIDS; do
        log "Stopping process: $pid"
        kill -TERM "$pid" 2>/dev/null || true
    done
    
    sleep 3
    
    # Force kill remaining
    STILL_RUNNING=$(pgrep -f "protonmail_email_bot.py" || true)
    if [ -n "$STILL_RUNNING" ]; then
        warning "Force killing remaining processes: $STILL_RUNNING"
        pkill -KILL -f "protonmail_email_bot.py" || true
    fi
fi

# Final check
if pgrep -f "protonmail_email_bot.py" > /dev/null; then
    warning "Some bot processes may still be running"
    echo "Active processes:"
    pgrep -f "protonmail_email_bot.py" | xargs ps -p
else
    success "All ProtonMail bot processes stopped"
fi

log "ProtonMail Email Bot stop completed"
echo ""
echo "✅ ProtonMail Email Bot stopped"
echo "📋 Logs preserved in: $LOG_FILE"
echo "🔄 Restart with: ./scripts/start_protonmail_email_bot.sh"
