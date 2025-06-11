#!/bin/bash

# ProtonMail Bridge Connection Test Script
# Tests IMAP and SMTP connectivity through ProtonMail Bridge

set -e

LOG_FILE="logs/protonmail_test.log"

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

# Test configuration
EMAIL="davide.courtault@proton.me"
IMAP_HOST="127.0.0.1"
IMAP_PORT="1143"
SMTP_HOST="127.0.0.1"
SMTP_PORT="1025"

mkdir -p logs

log "Starting ProtonMail Bridge connection tests..."
log "Email: $EMAIL"
log "IMAP: $IMAP_HOST:$IMAP_PORT"
log "SMTP: $SMTP_HOST:$SMTP_PORT"

# Test 1: Check if bridge process is running
log "Test 1: Checking ProtonMail Bridge process..."
if pgrep -f protonmail-bridge > /dev/null; then
    success "ProtonMail Bridge process is running"
    ps aux | grep protonmail-bridge | grep -v grep | tee -a "$LOG_FILE"
else
    error "ProtonMail Bridge process is not running"
    log "Try starting it with: ./start_protonmail_bridge.sh"
    exit 1
fi

# Test 2: Check if ports are open
log "Test 2: Checking if bridge ports are listening..."

if netstat -tlnp 2>/dev/null | grep ":$IMAP_PORT " > /dev/null; then
    success "IMAP port $IMAP_PORT is listening"
else
    error "IMAP port $IMAP_PORT is not listening"
fi

if netstat -tlnp 2>/dev/null | grep ":$SMTP_PORT " > /dev/null; then
    success "SMTP port $SMTP_PORT is listening"
else
    error "SMTP port $SMTP_PORT is not listening"
fi

# Test 3: Test TCP connectivity
log "Test 3: Testing TCP connectivity..."

log "Testing IMAP connectivity..."
if timeout 5 bash -c "echo >/dev/tcp/$IMAP_HOST/$IMAP_PORT" 2>/dev/null; then
    success "IMAP TCP connection successful"
else
    error "IMAP TCP connection failed"
fi

log "Testing SMTP connectivity..."
if timeout 5 bash -c "echo >/dev/tcp/$SMTP_HOST/$SMTP_PORT" 2>/dev/null; then
    success "SMTP TCP connection successful"
else
    error "SMTP TCP connection failed"
fi

# Test 4: Test IMAP protocol
log "Test 4: Testing IMAP protocol response..."
IMAP_RESPONSE=$(timeout 10 telnet $IMAP_HOST $IMAP_PORT 2>/dev/null | head -1 || echo "TIMEOUT")
if [[ "$IMAP_RESPONSE" == *"OK"* ]]; then
    success "IMAP protocol responding correctly"
    log "IMAP response: $IMAP_RESPONSE"
else
    warning "IMAP protocol response unclear: $IMAP_RESPONSE"
fi

# Test 5: Test SMTP protocol
log "Test 5: Testing SMTP protocol response..."
SMTP_RESPONSE=$(timeout 10 telnet $SMTP_HOST $SMTP_PORT 2>/dev/null | head -1 || echo "TIMEOUT")
if [[ "$SMTP_RESPONSE" == *"220"* ]]; then
    success "SMTP protocol responding correctly"
    log "SMTP response: $SMTP_RESPONSE"
else
    warning "SMTP protocol response unclear: $SMTP_RESPONSE"
fi

# Test 6: Check bridge configuration
log "Test 6: Checking bridge configuration..."
BRIDGE_CONFIG_DIR="$HOME/.config/protonmail/bridge"
if [ -d "$BRIDGE_CONFIG_DIR" ]; then
    success "Bridge configuration directory exists"
    log "Config directory: $BRIDGE_CONFIG_DIR"
    ls -la "$BRIDGE_CONFIG_DIR" | tee -a "$LOG_FILE"
else
    warning "Bridge configuration directory not found"
fi

# Test 7: Python IMAP test (if credentials available)
log "Test 7: Python IMAP connection test..."

# Check if .env file exists and has ProtonMail credentials
if [ -f ".env" ] && grep -q "PROTONMAIL_PASSWORD" .env; then
    log "Found ProtonMail credentials in .env, testing Python connection..."
    
    python3 << 'EOF' | tee -a "$LOG_FILE"
import imaplib
import os
import sys
from dotenv import load_dotenv

load_dotenv()

email = os.getenv('PROTONMAIL_ADDRESS', 'davide.courtault@proton.me')
password = os.getenv('PROTONMAIL_PASSWORD')
host = '127.0.0.1'
port = 1143

if not password:
    print("❌ PROTONMAIL_PASSWORD not found in .env")
    sys.exit(1)

try:
    print(f"Connecting to {host}:{port} with {email}...")
    mail = imaplib.IMAP4(host, port)
    mail.starttls()
    mail.login(email, password)
    
    # List mailboxes
    status, mailboxes = mail.list()
    print(f"✅ IMAP login successful!")
    print(f"Found {len(mailboxes)} mailboxes")
    
    # Select INBOX
    status, messages = mail.select('INBOX')
    print(f"INBOX contains {messages[0].decode()} messages")
    
    mail.logout()
    print("✅ IMAP test completed successfully!")
    
except Exception as e:
    print(f"❌ IMAP test failed: {e}")
    sys.exit(1)
EOF

else
    warning "No ProtonMail credentials found in .env file"
    log "To test Python connection, add your bridge credentials to .env:"
    log "PROTONMAIL_ADDRESS=davide.courtault@proton.me"
    log "PROTONMAIL_PASSWORD=your_bridge_password"
fi

# Summary
log ""
log "=== Test Summary ==="
success "ProtonMail Bridge connection tests completed!"
log "Check the full log in: $LOG_FILE"
log ""
log "If all tests passed, you can proceed to configure the email bot."
log "If tests failed, check:"
log "1. ProtonMail Bridge is running: systemctl status protonmail-bridge"
log "2. Bridge is logged in to your account"
log "3. Firewall settings allow localhost connections"
log "4. Bridge password is correct in .env file"

echo ""
echo "🎉 Connection tests completed! Check $LOG_FILE for detailed results."
