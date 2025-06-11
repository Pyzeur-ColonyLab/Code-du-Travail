#!/bin/bash

# Gmail Email Bot Quick Setup Script
# Sets up Gmail bot as reliable alternative to ProtonMail

set -e

LOG_FILE="logs/gmail_setup.log"

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

log "=== Gmail Email Bot Quick Setup ==="

echo ""
echo "🔄 Alternative Solution: Gmail Bot"
echo ""
echo "Since ProtonMail has connectivity issues, let's use Gmail which is:"
echo "✅ Reliable and stable"
echo "✅ Works well with AWS servers"
echo "✅ Easy to configure with app passwords"
echo "✅ No bridge required"
echo ""

# Get Gmail credentials
echo "📧 Gmail Configuration:"
echo ""
echo "1. You need a Gmail account for the bot"
echo "2. Enable 2FA on the account"
echo "3. Generate an app password"
echo ""

GMAIL_ADDRESS=$(input "Enter Gmail address for the bot: ")
if [ -z "$GMAIL_ADDRESS" ]; then
    error "Gmail address is required"
fi

echo ""
echo "🔐 App Password Setup:"
echo "1. Go to: https://myaccount.google.com/apppasswords"
echo "2. Create new app password for 'Mail'"
echo "3. Copy the 16-character password"
echo ""

APP_PASSWORD=$(input "Enter Gmail App Password (16 characters): ")
if [ -z "$APP_PASSWORD" ]; then
    error "App password is required"
fi

# Test Gmail connection
log "Testing Gmail connection..."

python3 << EOF
import imaplib
import smtplib
import sys

email = "$GMAIL_ADDRESS"
password = "$APP_PASSWORD"

print("Testing Gmail connection...")

try:
    # Test IMAP
    mail = imaplib.IMAP4_SSL("imap.gmail.com", 993)
    mail.login(email, password)
    print("✅ Gmail IMAP connection successful!")
    mail.logout()
    
    # Test SMTP
    server = smtplib.SMTP("smtp.gmail.com", 587)
    server.starttls()
    server.login(email, password)
    print("✅ Gmail SMTP connection successful!")
    server.quit()
    
    print("🎉 Gmail configuration working perfectly!")
    
except Exception as e:
    print(f"❌ Gmail connection failed: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    success "Gmail connection test passed!"
    
    # Update .env file
    log "Updating .env file with Gmail configuration..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
    fi
    
    # Remove old email configurations
    sed -i '/^PROTONMAIL_/d' .env 2>/dev/null || true
    sed -i '/^EMAIL_ADDRESS=/d' .env 2>/dev/null || true
    sed -i '/^EMAIL_PASSWORD=/d' .env 2>/dev/null || true
    
    # Add Gmail configuration
    {
        echo ""
        echo "# Gmail Configuration (Working Alternative)"
        echo "EMAIL_ADDRESS=$GMAIL_ADDRESS"
        echo "EMAIL_PASSWORD=$APP_PASSWORD"
        echo "GMAIL_IMAP_HOST=imap.gmail.com"
        echo "GMAIL_IMAP_PORT=993"
        echo "GMAIL_SMTP_HOST=smtp.gmail.com"
        echo "GMAIL_SMTP_PORT=587"
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
    
    success "Gmail configuration saved to .env"
    
    # Test the existing Gmail bot
    log "Testing existing Gmail email bot..."
    if [ -f "email_bot.py" ]; then
        log "Using existing Gmail email bot: email_bot.py"
        
        echo ""
        echo "🎉 Gmail Email Bot Ready!"
        echo ""
        echo "📧 Bot Email: $GMAIL_ADDRESS"
        echo "🔗 IMAP: imap.gmail.com:993"
        echo "📤 SMTP: smtp.gmail.com:587"
        echo "🤖 AI: Optimized for complete responses"
        echo ""
        echo "Start the bot with:"
        echo "./start_email_bot.sh --background"
        echo ""
        echo "Send test emails to: $GMAIL_ADDRESS"
        echo "Monitor logs: tail -f email_bot.log"
        echo ""
        
    else
        warning "email_bot.py not found, would need to adapt existing bot"
    fi
    
else
    error "Gmail connection test failed"
fi

log "Gmail setup completed"
echo ""
echo "📋 Check logs: $LOG_FILE"
