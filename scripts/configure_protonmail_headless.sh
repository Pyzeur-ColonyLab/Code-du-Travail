#!/bin/bash

# ProtonMail Bridge Headless Configuration Script
# Configures ProtonMail Bridge in pure headless mode without GUI

set -e

LOG_FILE="logs/protonmail_bridge_config.log"

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

log "Starting ProtonMail Bridge headless configuration..."

# Stop any existing bridge
if pgrep -f protonmail-bridge > /dev/null; then
    log "Stopping existing bridge..."
    if [ -f "scripts/stop_protonmail_bridge.sh" ]; then
        chmod +x scripts/stop_protonmail_bridge.sh
        ./scripts/stop_protonmail_bridge.sh
    else
        pkill -f protonmail-bridge || true
        sleep 3
    fi
fi

# Install missing dependencies
log "Installing missing dependencies..."
sudo yum install -y xorg-x11-server-Xvfb pass >> "$LOG_FILE" 2>&1 || {
    warning "Some dependencies may not be available, continuing..."
}

# Start bridge in completely headless mode
log "Starting ProtonMail Bridge in headless mode..."

# Set environment for headless operation
export DISPLAY=:99
export QT_QPA_PLATFORM=offscreen
export QT_LOGGING_RULES="*=false"

# Start virtual display if available
if command -v Xvfb &> /dev/null; then
    log "Starting virtual display..."
    Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
    sleep 2
else
    warning "Xvfb not available, using pure offscreen mode"
fi

# Start bridge with verbose logging to catch credentials
log "Starting bridge with credential capture..."
timeout 30s protonmail-bridge --noninteractive --log-level debug >> "$LOG_FILE" 2>&1 &
BRIDGE_PID=$!

sleep 5

# Check if bridge started
if ps -p $BRIDGE_PID > /dev/null; then
    success "Bridge started with PID: $BRIDGE_PID"
else
    warning "Bridge process may have exited, checking logs..."
fi

# Wait for ports to be available
log "Waiting for bridge ports to become available..."
for i in {1..30}; do
    if netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null && \
       netstat -tlnp 2>/dev/null | grep ":1025 " > /dev/null; then
        success "Bridge ports are now available!"
        break
    fi
    echo -n "."
    sleep 2
done

echo ""

# Check current status
if netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null; then
    success "IMAP port 1143 is listening"
else
    warning "IMAP port 1143 is not available"
fi

if netstat -tlnp 2>/dev/null | grep ":1025 " > /dev/null; then
    success "SMTP port 1025 is listening"
else
    warning "SMTP port 1025 is not available"
fi

echo ""
echo "=== ProtonMail Bridge Manual Configuration ==="
echo ""
echo "Since the bridge is running in headless mode, you need to configure it manually."
echo ""
echo "📧 Email: davide.courtault@proton.me"
echo ""

# For ProtonMail free accounts, we need to use a different approach
echo "🔑 For ProtonMail FREE accounts, Bridge access is limited."
echo "However, you can still configure the bot using these methods:"
echo ""
echo "Option 1: Use a temporary bridge password"
echo "- Some ProtonMail free accounts may have limited bridge access"
echo "- Try using your regular ProtonMail password first"
echo ""
echo "Option 2: Use app-specific password (if available)"
echo "- Check your ProtonMail settings for app passwords"
echo ""

PROTONMAIL_PASSWORD=$(input "Enter your ProtonMail password (or app password): ")

if [ -z "$PROTONMAIL_PASSWORD" ]; then
    error "Password is required"
fi

# Test the credentials directly
log "Testing ProtonMail credentials..."

# Create a simple test
cat > /tmp/test_protonmail.py << EOF
import imaplib
import smtplib
import sys
import socket

def test_imap(host, port, email, password):
    try:
        print(f"Testing IMAP connection to {host}:{port}...")
        mail = imaplib.IMAP4(host, port)
        
        # Try STARTTLS
        try:
            mail.starttls()
            print("✅ STARTTLS successful")
        except:
            print("⚠️  STARTTLS not available, trying plain connection")
        
        # Try login
        mail.login(email, password)
        print("✅ IMAP login successful!")
        
        # List mailboxes
        status, mailboxes = mail.list()
        print(f"Found {len(mailboxes)} mailboxes")
        
        mail.logout()
        return True
        
    except Exception as e:
        print(f"❌ IMAP test failed: {e}")
        return False

def test_smtp(host, port, email, password):
    try:
        print(f"Testing SMTP connection to {host}:{port}...")
        server = smtplib.SMTP(host, port)
        
        try:
            server.starttls()
            print("✅ SMTP STARTTLS successful")
        except:
            print("⚠️  SMTP STARTTLS not available")
        
        server.login(email, password)
        print("✅ SMTP login successful!")
        
        server.quit()
        return True
        
    except Exception as e:
        print(f"❌ SMTP test failed: {e}")
        return False

# Test bridge connection
email = "davide.courtault@proton.me"
password = "$PROTONMAIL_PASSWORD"

print("Testing ProtonMail Bridge connection...")
print("=" * 50)

imap_ok = test_imap("127.0.0.1", 1143, email, password)
smtp_ok = test_smtp("127.0.0.1", 1025, email, password)

if imap_ok and smtp_ok:
    print("\n🎉 All tests passed! ProtonMail Bridge is working correctly.")
    sys.exit(0)
else:
    print("\n❌ Bridge connection failed.")
    print("This might be because:")
    print("1. ProtonMail Bridge requires a paid account for IMAP/SMTP")
    print("2. The bridge is not properly configured")
    print("3. The password is incorrect")
    sys.exit(1)
EOF

# Run the test
if python3 /tmp/test_protonmail.py; then
    success "ProtonMail Bridge connection test passed!"
    
    # Save configuration
    log "Saving ProtonMail configuration..."
    
    if [ ! -f ".env" ]; then
        cp .env.example .env
    fi
    
    # Update .env with working credentials
    {
        echo ""
        echo "# ProtonMail Configuration (via Bridge)"
        echo "PROTONMAIL_ADDRESS=davide.courtault@proton.me"
        echo "PROTONMAIL_PASSWORD=$PROTONMAIL_PASSWORD"
        echo "PROTONMAIL_IMAP_HOST=127.0.0.1"
        echo "PROTONMAIL_IMAP_PORT=1143"
        echo "PROTONMAIL_SMTP_HOST=127.0.0.1"
        echo "PROTONMAIL_SMTP_PORT=1025"
    } >> .env
    
    success "Configuration saved to .env file"
    
else
    warning "ProtonMail Bridge connection failed"
    echo ""
    echo "🔄 Alternative Solutions:"
    echo ""
    echo "1. **Paid ProtonMail Account**: Bridge typically requires a paid subscription"
    echo "2. **Alternative Email**: We can configure the bot with Gmail/Outlook instead"
    echo "3. **ProtonMail Web API**: Use ProtonMail's web interface (more complex)"
    echo ""
    echo "Would you like to:"
    echo "a) Try with a different email service (Gmail/Outlook)"
    echo "b) Continue with ProtonMail web interface setup"
    echo "c) Upgrade to ProtonMail paid account"
    echo ""
fi

# Cleanup
rm -f /tmp/test_protonmail.py

log "Bridge configuration attempt completed"
echo ""
echo "Check logs: $LOG_FILE"
