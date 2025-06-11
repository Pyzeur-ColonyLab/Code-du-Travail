#!/bin/bash

# ProtonMail Bridge Account Configuration Script
# Forces account configuration through various methods

set -e

LOG_FILE="logs/protonmail_account_config.log"

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

log "=== ProtonMail Bridge Account Configuration ==="

# Check if bridge is running
if ! pgrep -f protonmail-bridge > /dev/null; then
    error "ProtonMail Bridge is not running. Start it first with ./scripts/start_protonmail_bridge.sh"
    exit 1
fi

# Check if ports are listening
if ! netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null; then
    error "IMAP port 1143 not listening"
    exit 1
fi

if ! netstat -tlnp 2>/dev/null | grep ":1025 " > /dev/null; then
    error "SMTP port 1025 not listening"
    exit 1
fi

success "Bridge is running and ports are active"

echo ""
echo "🔧 ProtonMail Account Configuration Methods"
echo ""

# Method 1: Try bridge CLI if available
log "Method 1: Attempting bridge CLI configuration..."

# Check for bridge CLI binary
BRIDGE_CLI=""
for path in "/usr/local/bin/bridge" "/usr/bin/bridge" "$HOME/.local/share/protonmail/bridge-v3/updates/*/bridge"; do
    if [ -f "$path" ]; then
        BRIDGE_CLI="$path"
        break
    fi
done

if [ -n "$BRIDGE_CLI" ]; then
    log "Found bridge CLI: $BRIDGE_CLI"
    
    echo "Attempting to configure account via CLI..."
    timeout 30s "$BRIDGE_CLI" --cli 2>&1 | tee -a "$LOG_FILE" || {
        warning "CLI configuration failed or timed out"
    }
else
    warning "Bridge CLI not found"
fi

# Method 2: Direct configuration file approach
log "Method 2: Creating configuration files..."

BRIDGE_CONFIG_DIR="$HOME/.config/protonmail/bridge"
mkdir -p "$BRIDGE_CONFIG_DIR"

# Get user credentials
echo ""
echo "📧 Enter your ProtonMail Plus credentials:"
EMAIL=$(input "Email (davide.courtault@proton.me): ")
if [ -z "$EMAIL" ]; then
    EMAIL="davide.courtault@proton.me"
fi

PASSWORD=$(input "Password: ")
if [ -z "$PASSWORD" ]; then
    error "Password is required"
    exit 1
fi

# Method 3: Automated GUI interaction
log "Method 3: Automated GUI configuration..."

# Kill existing bridge GUI
pkill -f bridge-gui || true
sleep 2

# Set up display
export DISPLAY=:99
export QT_QPA_PLATFORM=xcb

# Start bridge GUI in background
log "Starting bridge GUI..."
protonmail-bridge >> "$LOG_FILE" 2>&1 &
BRIDGE_PID=$!

sleep 10

# Try to interact with GUI using xdotool if available
if command -v xdotool &> /dev/null; then
    log "Using xdotool for GUI automation..."
    
    # Wait for bridge window
    sleep 5
    
    # Try to find and click "Add Account" button
    xdotool search --name "ProtonMail Bridge" windowactivate 2>/dev/null || true
    sleep 2
    
    # Send keyboard shortcuts for account addition
    xdotool key ctrl+n 2>/dev/null || true  # New account shortcut
    sleep 2
    
    # Type credentials
    xdotool type "$EMAIL" 2>/dev/null || true
    sleep 1
    xdotool key Tab 2>/dev/null || true
    xdotool type "$PASSWORD" 2>/dev/null || true
    sleep 1
    xdotool key Return 2>/dev/null || true
    
    log "Automated GUI interaction attempted"
    
else
    warning "xdotool not available for GUI automation"
    log "Installing xdotool..."
    sudo yum install -y xdotool >> "$LOG_FILE" 2>&1 || true
fi

# Method 4: Manual bridge interaction
log "Method 4: Manual bridge configuration instructions..."

echo ""
echo "🖥️  Manual Configuration Required"
echo ""
echo "Since automated methods may not work reliably, please follow these steps:"
echo ""
echo "1. On your LOCAL computer (with GUI), download ProtonMail Bridge:"
echo "   https://protonmail.com/bridge/install"
echo ""
echo "2. Install and configure it with your account:"
echo "   - Email: $EMAIL"
echo "   - Password: [your password]"
echo ""
echo "3. In the bridge, note the generated BRIDGE PASSWORD (16 chars)"
echo ""
echo "4. Come back here and we'll use that bridge password directly!"
echo ""

BRIDGE_PASSWORD=$(input "Enter the Bridge Password from your local setup (or press Enter to continue): ")

if [ -n "$BRIDGE_PASSWORD" ]; then
    log "Testing provided bridge password..."
    
    # Test the bridge password
    python3 << EOF
import imaplib
import smtplib
import sys

email = "$EMAIL"
bridge_password = "$BRIDGE_PASSWORD"

try:
    # Test IMAP
    mail = imaplib.IMAP4("127.0.0.1", 1143)
    mail.starttls()
    mail.login(email, bridge_password)
    print("✅ IMAP login successful with bridge password!")
    mail.logout()
    
    # Test SMTP
    server = smtplib.SMTP("127.0.0.1", 1025)
    server.starttls()
    server.login(email, bridge_password)
    print("✅ SMTP login successful with bridge password!")
    server.quit()
    
    print("🎉 Bridge password works! Saving configuration...")
    
except Exception as e:
    print(f"❌ Bridge password test failed: {e}")
    sys.exit(1)
EOF
    
    if [ $? -eq 0 ]; then
        success "Bridge password works!"
        
        # Save to .env file
        if [ ! -f ".env" ]; then
            cp .env.example .env
        fi
        
        # Update .env with working credentials
        {
            echo ""
            echo "# ProtonMail Bridge Configuration - WORKING"
            echo "PROTONMAIL_ADDRESS=$EMAIL"
            echo "PROTONMAIL_PASSWORD=$BRIDGE_PASSWORD"
            echo "PROTONMAIL_IMAP_HOST=127.0.0.1"
            echo "PROTONMAIL_IMAP_PORT=1143"
            echo "PROTONMAIL_SMTP_HOST=127.0.0.1"
            echo "PROTONMAIL_SMTP_PORT=1025"
        } >> .env
        
        success "Configuration saved to .env file!"
        
        echo ""
        echo "🎉 ProtonMail Bridge is now configured and ready!"
        echo "📧 Email: $EMAIL"
        echo "🔑 Bridge Password: [SAVED]"
        echo ""
        echo "Next steps:"
        echo "1. Test connection: ./scripts/test_protonmail_connection.sh"
        echo "2. Start email bot: ./scripts/start_protonmail_email_bot.sh"
        echo ""
        
    else
        error "Bridge password doesn't work"
    fi
else
    echo ""
    echo "⏭️  Alternative: Use existing email solution"
    echo ""
    echo "If ProtonMail Bridge configuration is too complex, we can:"
    echo "1. Use Gmail with app passwords (simpler)"
    echo "2. Use Outlook/Hotmail"
    echo "3. Continue debugging ProtonMail Bridge"
    echo ""
fi

# Cleanup
kill $BRIDGE_PID 2>/dev/null || true

log "Account configuration session completed"
echo ""
echo "📋 Check logs: $LOG_FILE"
