#!/bin/bash

# Outlook/Hotmail Email Bot Setup Script
# Alternative solution when Gmail/ProtonMail don't work

set -e

LOG_FILE="logs/outlook_setup.log"

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

log "=== Outlook/Hotmail Email Bot Setup ==="

echo ""
echo "🔄 Alternative Solution: Outlook/Hotmail Bot"
echo ""
echo "Outlook/Hotmail advantages:"
echo "✅ Simple configuration (no app passwords needed)"
echo "✅ Works well with AWS servers"
echo "✅ Less restrictive than Gmail"
echo "✅ Free and reliable"
echo ""

# Get Outlook credentials
echo "📧 Outlook/Hotmail Configuration:"
echo ""
echo "You can use:"
echo "1. Existing Outlook.com/Hotmail.com account"
echo "2. Create new account at outlook.com"
echo ""

OUTLOOK_ADDRESS=$(input "Enter Outlook/Hotmail address: ")
if [ -z "$OUTLOOK_ADDRESS" ]; then
    error "Email address is required"
fi

OUTLOOK_PASSWORD=$(input "Enter password: ")
if [ -z "$OUTLOOK_PASSWORD" ]; then
    error "Password is required"
fi

# Test Outlook connection
log "Testing Outlook connection..."

python3 << EOF
import imaplib
import smtplib
import sys

email = "$OUTLOOK_ADDRESS"
password = "$OUTLOOK_PASSWORD"

print("Testing Outlook connection...")
print("=" * 50)

try:
    # Test IMAP
    print("Testing IMAP connection to outlook.office365.com:993...")
    mail = imaplib.IMAP4_SSL("outlook.office365.com", 993)
    mail.login(email, password)
    print("✅ Outlook IMAP connection successful!")
    mail.logout()
    
    # Test SMTP
    print("Testing SMTP connection to smtp-mail.outlook.com:587...")
    server = smtplib.SMTP("smtp-mail.outlook.com", 587)
    server.starttls()
    server.login(email, password)
    print("✅ Outlook SMTP connection successful!")
    server.quit()
    
    print("🎉 Outlook configuration working perfectly!")
    
except Exception as e:
    print(f"❌ Outlook connection failed: {e}")
    print("This might be because:")
    print("1. 2FA is enabled (need app password)")
    print("2. Less secure app access is disabled")
    print("3. Account is new and needs verification")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    success "Outlook connection test passed!"
    
    # Update .env file
    log "Updating .env file with Outlook configuration..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
    fi
    
    # Remove old email configurations
    sed -i '/^PROTONMAIL_/d' .env 2>/dev/null || true
    sed -i '/^EMAIL_ADDRESS=/d' .env 2>/dev/null || true
    sed -i '/^EMAIL_PASSWORD=/d' .env 2>/dev/null || true
    sed -i '/^GMAIL_/d' .env 2>/dev/null || true
    
    # Add Outlook configuration
    {
        echo ""
        echo "# Outlook/Hotmail Configuration (Working Solution)"
        echo "EMAIL_ADDRESS=$OUTLOOK_ADDRESS"
        echo "EMAIL_PASSWORD=$OUTLOOK_PASSWORD"
        echo "EMAIL_IMAP_HOST=outlook.office365.com"
        echo "EMAIL_IMAP_PORT=993"
        echo "EMAIL_SMTP_HOST=smtp-mail.outlook.com"
        echo "EMAIL_SMTP_PORT=587"
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
    
    success "Outlook configuration saved to .env"
    
    echo ""
    echo "🎉 Outlook Email Bot Ready!"
    echo ""
    echo "📧 Bot Email: $OUTLOOK_ADDRESS"
    echo "🔗 IMAP: outlook.office365.com:993"
    echo "📤 SMTP: smtp-mail.outlook.com:587"
    echo "🤖 AI: Optimized for complete responses"
    echo ""
    echo "Next steps:"
    echo "1. Test the bot: python3 email_bot.py"
    echo "2. Or start in background: ./start_email_bot.sh --background"
    echo "3. Send test emails to: $OUTLOOK_ADDRESS"
    echo "4. Monitor logs: tail -f email_bot.log"
    echo ""
    
else
    error "Outlook connection test failed"
    echo ""
    echo "🔄 Alternative solutions:"
    echo "1. Create new Outlook account at outlook.com"
    echo "2. Check if 2FA is enabled (may need app password)"
    echo "3. Enable 'Less secure app access' in Outlook settings"
    echo ""
fi

log "Outlook setup completed"
echo ""
echo "📋 Check logs: $LOG_FILE"
