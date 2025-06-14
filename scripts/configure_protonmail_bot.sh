#!/bin/bash

# ProtonMail Configuration Script
# Configures the bot environment for ProtonMail integration

set -e

LOG_FILE="logs/protonmail_config.log"

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

input() {
    echo -ne "${YELLOW}[INPUT]${NC} $1"
    read -r response
    echo "$response"
}

mkdir -p logs

log "Starting ProtonMail bot configuration..."

# Check if ProtonMail Bridge is installed
if ! command -v protonmail-bridge &> /dev/null; then
    error "ProtonMail Bridge is not installed. Run ./scripts/install_protonmail_bridge.sh first"
fi

# Check if bridge is running
if ! pgrep -f protonmail-bridge > /dev/null; then
    warning "ProtonMail Bridge is not running. Starting it now..."
    if [ -f "scripts/start_protonmail_bridge.sh" ]; then
        chmod +x scripts/start_protonmail_bridge.sh
        ./scripts/start_protonmail_bridge.sh
        sleep 5
    else
        error "Bridge startup script not found in scripts/ directory"
    fi
fi

# Update dependencies
log "Installing Python dependencies..."
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1
    success "Dependencies installed successfully"
else
    warning "Virtual environment not found. Creating one..."
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    pip install -r requirements.txt >> "$LOG_FILE" 2>&1
    success "Virtual environment created and dependencies installed"
fi

# Configure .env file
log "Configuring environment variables..."

if [ ! -f ".env" ]; then
    log "Creating .env file from template..."
    cp .env.example .env
fi

echo ""
echo "=== ProtonMail Bot Configuration ==="
echo ""

# Check if bridge is responding
log "Checking bridge connectivity..."
if timeout 5 bash -c "echo >/dev/tcp/127.0.0.1/1143" 2>/dev/null; then
    success "IMAP port 1143 is accessible"
else
    error "IMAP port 1143 is not accessible. Make sure ProtonMail Bridge is running and logged in."
fi

if timeout 5 bash -c "echo >/dev/tcp/127.0.0.1/1025" 2>/dev/null; then
    success "SMTP port 1025 is accessible"
else
    error "SMTP port 1025 is not accessible. Make sure ProtonMail Bridge is running and logged in."
fi

# Get existing values from .env if they exist
EXISTING_TELEGRAM_TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" .env 2>/dev/null | cut -d'=' -f2 || echo "")
EXISTING_HF_TOKEN=$(grep "^HUGGING_FACE_TOKEN=" .env 2>/dev/null | cut -d'=' -f2 || echo "")

# Ask for ProtonMail Bridge password
echo "📧 ProtonMail Configuration:"
echo "The ProtonMail Bridge generates a unique password for IMAP/SMTP access."
echo ""
echo "To get your bridge password:"
echo "1. Run: protonmail-bridge --cli"
echo "2. Login with your ProtonMail credentials"
echo "3. The bridge will display a password for IMAP/SMTP"
echo "4. Copy that password (usually 16 characters)"
echo ""

BRIDGE_PASSWORD=$(input "Enter your ProtonMail Bridge password: ")

if [ -z "$BRIDGE_PASSWORD" ]; then
    error "Bridge password is required"
fi

# Test the credentials
log "Testing ProtonMail Bridge credentials..."
python3 << EOF
import imaplib
import sys

try:
    print("Testing IMAP connection...")
    mail = imaplib.IMAP4('127.0.0.1', 1143)
    mail.starttls()
    mail.login('davide.courtault@proton.me', '$BRIDGE_PASSWORD')
    print("✅ IMAP login successful!")
    
    # List mailboxes
    status, mailboxes = mail.list()
    print(f"Found {len(mailboxes)} mailboxes")
    
    mail.logout()
    
except Exception as e:
    print(f"❌ IMAP test failed: {e}")
    print("Please check:")
    print("1. ProtonMail Bridge is running")
    print("2. You are logged into your ProtonMail account in the bridge")
    print("3. The bridge password is correct")
    sys.exit(1)
EOF

if [ $? -ne 0 ]; then
    error "ProtonMail credentials test failed"
fi

# Update .env file with ProtonMail settings
log "Updating .env file with ProtonMail configuration..."

# Remove old email configurations
sed -i '/^EMAIL_ADDRESS=/d' .env 2>/dev/null || true
sed -i '/^EMAIL_PASSWORD=/d' .env 2>/dev/null || true
sed -i '/^PROTONMAIL_/d' .env 2>/dev/null || true
sed -i '/^EMAIL_/d' .env 2>/dev/null || true

# Add ProtonMail configuration
{
    echo ""
    echo "# ProtonMail Configuration (via Bridge)"
    echo "PROTONMAIL_ADDRESS=davide.courtault@proton.me"
    echo "PROTONMAIL_PASSWORD=$BRIDGE_PASSWORD"
    echo "PROTONMAIL_IMAP_HOST=127.0.0.1"
    echo "PROTONMAIL_IMAP_PORT=1143"
    echo "PROTONMAIL_SMTP_HOST=127.0.0.1"
    echo "PROTONMAIL_SMTP_PORT=1025"
    echo ""
    echo "# Email Bot Parameters for Complete and Precise Responses"
    echo "EMAIL_MAX_TOKENS=1500"
    echo "EMAIL_TEMPERATURE=0.3"
    echo "EMAIL_TOP_P=0.95"
    echo "EMAIL_TOP_K=50"
    echo "EMAIL_REPETITION_PENALTY=1.15"
    echo ""
    echo "# Signature and Disclaimer"
    echo "EMAIL_SIGNATURE=Assistant IA Code du Travail - ColonyLab"
    echo "EMAIL_DISCLAIMER=Cette réponse est fournie à titre informatif uniquement. Pour des conseils juridiques précis et personnalisés, consultez un avocat spécialisé en droit du travail."
} >> .env

success "ProtonMail configuration added to .env"

# Test connection with the updated configuration
log "Running comprehensive connection test..."
if [ -f "scripts/test_protonmail_connection.sh" ]; then
    chmod +x scripts/test_protonmail_connection.sh
    ./scripts/test_protonmail_connection.sh
else
    warning "Connection test script not found"
fi

# Summary
echo ""
echo "=== Configuration Summary ==="
success "ProtonMail bot configuration completed!"
echo ""
echo "📧 Email: davide.courtault@proton.me"
echo "🔗 IMAP: 127.0.0.1:1143"
echo "📤 SMTP: 127.0.0.1:1025"
echo "🤖 AI Parameters: Optimized for complete and precise responses"
echo ""
echo "Next steps:"
echo "1. Start the email bot: ./scripts/start_protonmail_email_bot.sh"
echo "2. Send a test email to: davide.courtault@proton.me"
echo "3. Monitor logs: tail -f logs/protonmail_email_bot.log"
echo ""
log "Configuration saved to .env file"
log "Check logs in: $LOG_FILE"

echo "🎉 ProtonMail bot configuration completed!"
