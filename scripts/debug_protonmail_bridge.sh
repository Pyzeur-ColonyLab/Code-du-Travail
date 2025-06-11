#!/bin/bash

# ProtonMail Bridge Advanced Debugging and Configuration Script
# Comprehensive bridge troubleshooting for Amazon Linux

set -e

LOG_FILE="logs/protonmail_bridge_debug.log"

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

mkdir -p logs

log "=== ProtonMail Bridge Advanced Debugging ==="

# Step 1: Kill all bridge processes
log "Step 1: Cleaning up existing bridge processes..."
pkill -f protonmail-bridge || true
pkill -f bridge-gui || true
pkill -f proton-bridge || true
sleep 3

# Step 2: Remove lock files
log "Step 2: Removing lock files..."
rm -f ~/.config/protonmail/bridge/*.lock 2>/dev/null || true
rm -f ~/.cache/protonmail/bridge/*.lock 2>/dev/null || true

# Step 3: Check bridge binary
log "Step 3: Checking bridge installation..."
BRIDGE_BINARY=$(which protonmail-bridge 2>/dev/null || echo "")
if [ -z "$BRIDGE_BINARY" ]; then
    error "ProtonMail Bridge binary not found"
    exit 1
fi

log "Bridge binary found: $BRIDGE_BINARY"
$BRIDGE_BINARY --version 2>/dev/null || log "Version check failed"

# Step 4: Check dependencies
log "Step 4: Checking system dependencies..."

# Check for X11 libraries
if ! ldconfig -p | grep -q libX11; then
    warning "X11 libraries may be missing"
    log "Installing X11 libraries..."
    sudo yum install -y libX11 libX11-devel xorg-x11-server-Xvfb >> "$LOG_FILE" 2>&1
fi

# Step 5: Start virtual display with more options
log "Step 5: Starting virtual display with extended options..."
pkill -f "Xvfb :99" || true
sleep 2

# Try different Xvfb configurations
if command -v Xvfb &> /dev/null; then
    log "Starting Xvfb with full configuration..."
    Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    XVFB_PID=$!
    sleep 3
    
    if ps -p $XVFB_PID > /dev/null; then
        success "Xvfb started successfully"
        export DISPLAY=:99
    else
        warning "Xvfb failed to start"
    fi
else
    warning "Xvfb not available"
fi

# Step 6: Set comprehensive environment
log "Step 6: Setting bridge environment..."
export DISPLAY=:99
export QT_QPA_PLATFORM=offscreen
export QT_LOGGING_RULES="*=false"
export XDG_RUNTIME_DIR="/tmp/runtime-$(id -u)"
export TMPDIR="/tmp"
export QT_X11_NO_MITSHM=1
export QT_GRAPHICSSYSTEM=native

mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null || true

# Step 7: Try different bridge startup methods
log "Step 7: Attempting bridge startup..."

# Method 1: Direct CLI mode
log "Method 1: Trying direct CLI mode..."
timeout 15s $BRIDGE_BINARY --cli --noninteractive >> "$LOG_FILE" 2>&1 &
CLI_PID=$!
sleep 10

if ps -p $CLI_PID > /dev/null 2>&1; then
    success "Bridge CLI started"
    kill $CLI_PID 2>/dev/null || true
else
    warning "CLI mode failed"
fi

# Method 2: GUI mode in background
log "Method 2: Trying GUI mode in virtual display..."
timeout 20s $BRIDGE_BINARY --log-level debug >> "$LOG_FILE" 2>&1 &
GUI_PID=$!
sleep 15

# Check if ports are now listening
log "Checking if bridge ports are available..."
IMAP_LISTENING=false
SMTP_LISTENING=false

for i in {1..10}; do
    if netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null; then
        IMAP_LISTENING=true
        success "IMAP port 1143 is listening!"
        break
    fi
    sleep 2
done

for i in {1..10}; do
    if netstat -tlnp 2>/dev/null | grep ":1025 " > /dev/null; then
        SMTP_LISTENING=true
        success "SMTP port 1025 is listening!"
        break
    fi
    sleep 2
done

# Step 8: Advanced port testing
log "Step 8: Advanced connectivity testing..."

if [ "$IMAP_LISTENING" = true ] && [ "$SMTP_LISTENING" = true ]; then
    success "Both ports are listening! Testing protocols..."
    
    # Test IMAP protocol
    log "Testing IMAP protocol response..."
    IMAP_RESPONSE=$(timeout 5 telnet 127.0.0.1 1143 << EOF 2>/dev/null | head -1
quit
EOF
)
    log "IMAP response: $IMAP_RESPONSE"
    
    # Test SMTP protocol  
    log "Testing SMTP protocol response..."
    SMTP_RESPONSE=$(timeout 5 telnet 127.0.0.1 1025 << EOF 2>/dev/null | head -1
quit
EOF
)
    log "SMTP response: $SMTP_RESPONSE"
    
    success "Bridge appears to be working!"
    
    # Now try to configure account
    log "Step 9: Account configuration..."
    echo ""
    echo "🎉 Bridge is running! Now let's configure your account."
    echo ""
    echo "Since the bridge is now working, we need to add your ProtonMail account."
    echo "This requires the bridge GUI interface."
    echo ""
    
    # Check if we can use the GUI
    if [ -n "$DISPLAY" ]; then
        log "Attempting GUI configuration..."
        echo "Opening bridge configuration GUI..."
        $BRIDGE_BINARY &
        sleep 5
        
        echo ""
        echo "📋 Manual Configuration Steps:"
        echo "1. The bridge GUI should open (may be in virtual display)"
        echo "2. Click 'Add Account' or '+'"
        echo "3. Enter: davide.courtault@proton.me"
        echo "4. Enter your ProtonMail Plus password"
        echo "5. Note the bridge password shown (16 characters)"
        echo ""
        echo "Bridge Password will be displayed in the GUI."
        echo "Copy it and run: echo 'BRIDGE_PASSWORD_HERE' > bridge_password.txt"
        echo ""
    fi
    
else
    error "Bridge ports are not listening"
    log "Detailed port analysis:"
    netstat -tlnp 2>/dev/null | grep -E ":(1143|1025|1142|1024)" || log "No bridge ports found"
    
    log "Bridge process status:"
    ps aux | grep -E "(proton|bridge)" | grep -v grep || log "No bridge processes found"
    
    log "Trying alternative approach..."
    
    # Alternative: Try bridge with specific config
    CONFIG_DIR="$HOME/.config/protonmail/bridge"
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/bridge.conf" << EOF
{
    "user_id": "",
    "username": "davide.courtault@proton.me",
    "imap_port": 1143,
    "smtp_port": 1025,
    "imap_security": "starttls",
    "smtp_security": "starttls"
}
EOF
    
    log "Created bridge configuration file"
    log "Restarting bridge with configuration..."
    
    pkill -f protonmail-bridge || true
    sleep 3
    
    $BRIDGE_BINARY --log-level debug >> "$LOG_FILE" 2>&1 &
    NEW_PID=$!
    sleep 10
    
    if netstat -tlnp 2>/dev/null | grep ":1143 " > /dev/null; then
        success "Bridge started with custom configuration!"
    else
        error "Bridge still not responding"
        
        echo ""
        echo "🔄 Alternative Solutions:"
        echo ""
        echo "1. **Manual Bridge Setup:**"
        echo "   - Download bridge GUI on your local machine"
        echo "   - Configure account there"
        echo "   - Copy bridge password to server"
        echo ""
        echo "2. **Use ProtonMail App Password:**"
        echo "   - Go to ProtonMail Settings > Security"
        echo "   - Generate an app password"
        echo "   - Use it directly in the bot"
        echo ""
        echo "3. **Network Configuration:**"
        echo "   - Check if firewall blocks local ports"
        echo "   - Verify no other services use ports 1143/1025"
        echo ""
    fi
fi

log "=== Debugging session completed ==="
echo ""
echo "📋 Check detailed logs: $LOG_FILE"
echo "🔄 Current bridge status:"
ps aux | grep protonmail-bridge | grep -v grep || echo "No bridge running"
netstat -tlnp 2>/dev/null | grep -E ":(1143|1025)" || echo "No bridge ports listening"
