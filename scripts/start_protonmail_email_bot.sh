#!/bin/bash

# ProtonMail Email Bot Startup Script
# Starts the ProtonMail email bot with proper monitoring and logging

set -e

BOT_NAME="protonmail_email_bot"
BOT_SCRIPT="protonmail_email_bot.py"
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

# Create logs directory
mkdir -p logs

log "Starting ProtonMail Email Bot..."

# Check if script exists
if [ ! -f "$BOT_SCRIPT" ]; then
    error "Bot script not found: $BOT_SCRIPT"
fi

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if ps -p "$OLD_PID" > /dev/null 2>&1; then
        warning "Bot is already running with PID: $OLD_PID"
        echo "Use ./scripts/stop_protonmail_email_bot.sh to stop it first"
        exit 1
    else
        log "Removing stale PID file"
        rm -f "$PID_FILE"
    fi
fi

# Check virtual environment
if [ ! -d "venv" ]; then
    error "Virtual environment not found. Run: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
fi

# Activate virtual environment
log "Activating virtual environment..."
source venv/bin/activate

# Check dependencies
log "Checking dependencies..."
python3 -c "import torch, transformers, peft" || {
    error "Required dependencies not installed. Run: pip install -r requirements.txt"
}

# Check .env configuration
if [ ! -f ".env" ]; then
    error ".env file not found. Run ./scripts/configure_protonmail_bot.sh first"
fi

# Verify ProtonMail configuration
log "Verifying ProtonMail configuration..."
python3 << 'EOF'
import os
from dotenv import load_dotenv

load_dotenv()

required_vars = [
    'PROTONMAIL_ADDRESS',
    'PROTONMAIL_PASSWORD',
    'HUGGING_FACE_TOKEN'
]

missing = []
for var in required_vars:
    if not os.getenv(var):
        missing.append(var)

if missing:
    print(f"Missing required environment variables: {', '.join(missing)}")
    exit(1)

print("✅ Configuration check passed")
EOF

if [ $? -ne 0 ]; then
    error "Configuration check failed"
fi

# Check ProtonMail Bridge connection
log "Testing ProtonMail Bridge connection..."
python3 << 'EOF'
import imaplib
import os
from dotenv import load_dotenv

load_dotenv()

try:
    host = os.getenv('PROTONMAIL_IMAP_HOST', '127.0.0.1')
    port = int(os.getenv('PROTONMAIL_IMAP_PORT', '1143'))
    email_addr = os.getenv('PROTONMAIL_ADDRESS')
    password = os.getenv('PROTONMAIL_PASSWORD')
    
    mail = imaplib.IMAP4(host, port)
    mail.starttls()
    mail.login(email_addr, password)
    mail.logout()
    print("✅ ProtonMail Bridge connection successful")
    
except Exception as e:
    print(f"❌ ProtonMail Bridge connection failed: {e}")
    print("Make sure ProtonMail Bridge is running and configured")
    exit(1)
EOF

if [ $? -ne 0 ]; then
    error "ProtonMail Bridge connection test failed"
fi

# Parse command line arguments
BACKGROUND=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --background|-b)
            BACKGROUND=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--background|-b] [--help|-h]"
            echo "  --background, -b: Run bot in background"
            echo "  --help, -h: Show this help"
            exit 0
            ;;
        *)
            warning "Unknown option: $1"
            shift
            ;;
    esac
done

# Start the bot
if [ "$BACKGROUND" = true ]; then
    log "Starting ProtonMail bot in background..."
    nohup python3 "$BOT_SCRIPT" > "$LOG_FILE" 2>&1 &
    BOT_PID=$!
    echo $BOT_PID > "$PID_FILE"
    
    # Wait a moment to check if it started successfully
    sleep 3
    if ps -p $BOT_PID > /dev/null; then
        success "ProtonMail bot started successfully in background!"
        echo ""
        echo "🎉 ProtonMail Email Bot is running!"
        echo "📧 Monitoring: davide.courtault@proton.me"
        echo "🔄 PID: $BOT_PID"
        echo "📋 Logs: $LOG_FILE"
        echo "⏹️  Stop: ./scripts/stop_protonmail_email_bot.sh"
        echo ""
        echo "The bot will now automatically:"
        echo "• Monitor incoming emails every 30 seconds"
        echo "• Generate precise and complete responses"
        echo "• Send professional formatted replies"
        echo "• Log all activities"
        echo ""
        log "Bot running with PID: $BOT_PID"
    else
        error "Bot failed to start. Check logs: $LOG_FILE"
    fi
else
    log "Starting ProtonMail bot in foreground..."
    echo ""
    echo "🎉 ProtonMail Email Bot starting..."
    echo "📧 Monitoring: davide.courtault@proton.me"
    echo "📋 Logs: $LOG_FILE"
    echo "⏹️  Stop: Ctrl+C"
    echo ""
    
    # Run in foreground
    python3 "$BOT_SCRIPT"
fi
