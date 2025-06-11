#!/bin/bash

# ProtonMail Bridge Account Addition Script
# Adds ProtonMail Business account to running bridge

set -e

LOG_FILE="logs/bridge_account_setup.log"

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

input() {
    echo -ne "${YELLOW}[INPUT]${NC} $1"
    read -r response
    echo "$response"
}

mkdir -p logs

log "=== ProtonMail Bridge Account Setup ==="

# Check if bridge is running
if ! pgrep -f protonmail-bridge > /dev/null; then
    echo "❌ Bridge not running. Start it first!"
    exit 1
fi

# Check if ports are listening
if ! netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null; then
    echo "❌ IMAP port not listening"
    exit 1
fi

success "Bridge is running and ports are active"

echo ""
echo "🔑 ProtonMail Business Account Configuration"
echo ""
echo "Your account details:"
echo "Email: davide.courtault@cryptomaltese.com"
echo ""

EMAIL=$(input "Confirm email address (davide.courtault@cryptomaltese.com): ")
if [ -z "$EMAIL" ]; then
    EMAIL="davide.courtault@cryptomaltese.com"
fi

PASSWORD=$(input "Enter your ProtonMail password: ")
if [ -z "$PASSWORD" ]; then
    echo "❌ Password required"
    exit 1
fi

# Try to add account via Bridge CLI if available
log "Attempting to add account to bridge..."

# Method 1: Direct bridge configuration
echo ""
echo "🔧 Adding account to bridge..."

# Check for bridge CLI
BRIDGE_CLI=""
for path in "/usr/local/bin/bridge" "/usr/bin/bridge" "/usr/lib/protonmail/bridge/bridge" "$HOME/.local/share/protonmail/bridge-v3/updates/*/bridge"; do
    if [ -f "$path" ]; then
        BRIDGE_CLI="$path"
        break
    fi
done

if [ -n "$BRIDGE_CLI" ]; then
    log "Found bridge CLI: $BRIDGE_CLI"
    
    echo "Attempting CLI configuration..."
    timeout 30s "$BRIDGE_CLI" --cli << EOF || {
        warning "CLI configuration failed or timed out"
    }
add account
$EMAIL
$PASSWORD
quit
EOF
else
    warning "Bridge CLI not found"
fi

# Method 2: Bridge API approach
log "Trying Bridge API approach..."

# Bridge typically runs a local API
API_RESPONSE=$(curl -s -X POST http://127.0.0.1:8080/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" 2>/dev/null || echo "API_FAILED")

if [ "$API_RESPONSE" != "API_FAILED" ]; then
    log "Bridge API response: $API_RESPONSE"
else
    warning "Bridge API not available"
fi

# Method 3: Test if account was added
log "Testing if account was added..."

sleep 5

python3 << EOF
import imaplib
import smtplib

email = "$EMAIL"
password = "$PASSWORD"

print("Testing Bridge after account addition...")

try:
    mail = imaplib.IMAP4("127.0.0.1", 1143)
    mail.starttls()
    mail.login(email, password)
    print("✅ Account successfully added to Bridge!")
    mail.logout()
except Exception as e:
    print(f"❌ Account still not working: {e}")
    print("Manual configuration required")
EOF

echo ""
echo "📋 Manual Configuration Instructions:"
echo ""
echo "If automatic setup failed, you need to:"
echo "1. On your LOCAL computer, download ProtonMail Bridge"
echo "2. Configure davide.courtault@cryptomaltese.com in it"
echo "3. Get the Bridge password (16 characters)"
echo "4. Use that password on this server"
echo ""

BRIDGE_PASSWORD=$(input "Enter Bridge password from local setup (or skip): ")

if [ -n "$BRIDGE_PASSWORD" ]; then
    log "Testing with provided bridge password..."
    
    python3 << EOF
import imaplib
import smtplib

email = "$EMAIL"
bridge_password = "$BRIDGE_PASSWORD"

try:
    # Test with bridge password
    mail = imaplib.IMAP4("127.0.0.1", 1143)
    mail.starttls()
    mail.login(email, bridge_password)
    print("✅ Bridge password works!")
    mail.logout()
    
    # Save configuration
    print("Saving configuration...")
    
except Exception as e:
    print(f"❌ Bridge password failed: {e}")
EOF

    if [ $? -eq 0 ]; then
        # Save working configuration
        {
            echo ""
            echo "# ProtonMail Business Bridge Configuration"
            echo "EMAIL_ADDRESS=$EMAIL"
            echo "EMAIL_PASSWORD=$BRIDGE_PASSWORD"
            echo "EMAIL_IMAP_HOST=127.0.0.1"
            echo "EMAIL_IMAP_PORT=1143"
            echo "EMAIL_SMTP_HOST=127.0.0.1"
            echo "EMAIL_SMTP_PORT=1025"
        } >> .env
        
        success "Configuration saved to .env!"
        
        echo ""
        echo "🎉 ProtonMail Business Bridge is ready!"
        echo "📧 Email: $EMAIL"
        echo "🔗 Via Bridge: localhost:1143/1025"
        echo ""
        echo "Start the bot with: python3 email_bot.py"
    fi
else
    echo ""
    echo "⏭️  Next steps:"
    echo "1. Configure bridge on local machine"
    echo "2. Get bridge password"
    echo "3. Re-run this script with bridge password"
fi

log "Bridge account setup completed"
