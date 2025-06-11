#!/bin/bash

# ProtonMail Bridge Installation Script for Amazon Linux
# This script installs and configures ProtonMail Bridge in headless mode

set -e

LOG_FILE="logs/protonmail_setup.log"
BRIDGE_VERSION="3.0.19"
BRIDGE_DIR="/opt/protonmail-bridge"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log "Starting ProtonMail Bridge installation for Amazon Linux..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root for security reasons"
fi

# Check system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH_SUFFIX="amd64"
        ;;
    aarch64)
        ARCH_SUFFIX="arm64"
        ;;
    *)
        error "Unsupported architecture: $ARCH"
        ;;
esac

log "Detected architecture: $ARCH ($ARCH_SUFFIX)"

# Update system packages
log "Updating system packages..."
sudo yum update -y >> "$LOG_FILE" 2>&1

# Install required dependencies
log "Installing dependencies..."
sudo yum install -y \
    wget \
    curl \
    gnupg2 \
    pass \
    gpg \
    xvfb \
    dbus-x11 \
    libsecret \
    keyutils \
    >> "$LOG_FILE" 2>&1

# Install ProtonMail Bridge
log "Downloading ProtonMail Bridge v${BRIDGE_VERSION}..."

BRIDGE_URL="https://github.com/ProtonMail/proton-bridge/releases/download/v${BRIDGE_VERSION}/protonmail-bridge_${BRIDGE_VERSION}-1_${ARCH_SUFFIX}.rpm"

cd /tmp
wget -O "protonmail-bridge.rpm" "$BRIDGE_URL" >> "$LOG_FILE" 2>&1

if [ ! -f "protonmail-bridge.rpm" ]; then
    error "Failed to download ProtonMail Bridge"
fi

log "Installing ProtonMail Bridge..."
sudo rpm -i protonmail-bridge.rpm >> "$LOG_FILE" 2>&1 || {
    warning "RPM installation failed, trying to force install..."
    sudo rpm -i --force protonmail-bridge.rpm >> "$LOG_FILE" 2>&1
}

# Verify installation
if ! command -v protonmail-bridge &> /dev/null; then
    error "ProtonMail Bridge installation failed"
fi

success "ProtonMail Bridge installed successfully"

# Create bridge configuration directory
BRIDGE_CONFIG_DIR="$HOME/.config/protonmail/bridge"
mkdir -p "$BRIDGE_CONFIG_DIR"

# Create systemd service for ProtonMail Bridge
log "Creating systemd service..."

sudo tee /etc/systemd/system/protonmail-bridge.service > /dev/null << EOF
[Unit]
Description=ProtonMail Bridge
After=network.target

[Service]
Type=simple
User=$USER
Environment=DISPLAY=:99
Environment=QT_QPA_PLATFORM=offscreen
ExecStartPre=/usr/bin/Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
ExecStart=/usr/local/bin/protonmail-bridge --noninteractive --log-level debug
ExecStop=/bin/kill -TERM \$MAINPID
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create bridge startup script
log "Creating bridge startup script..."

cat > "$HOME/start_protonmail_bridge.sh" << 'EOF'
#!/bin/bash

# ProtonMail Bridge Startup Script
# Starts bridge in headless mode with virtual display

export DISPLAY=:99
export QT_QPA_PLATFORM=offscreen

# Start virtual display if not running
if ! pgrep -f "Xvfb :99" > /dev/null; then
    Xvfb :99 -screen 0 1024x768x24 -nolisten tcp &
    sleep 2
fi

# Start ProtonMail Bridge
protonmail-bridge --noninteractive --log-level info &

echo "ProtonMail Bridge started in headless mode"
echo "Check status with: systemctl status protonmail-bridge"
EOF

chmod +x "$HOME/start_protonmail_bridge.sh"

# Create bridge configuration script
log "Creating bridge configuration script..."

cat > "$HOME/configure_protonmail_bridge.sh" << 'EOF'
#!/bin/bash

# ProtonMail Bridge Configuration Script
# Configures bridge for davide.courtault@proton.me

EMAIL="davide.courtault@proton.me"
CONFIG_DIR="$HOME/.config/protonmail/bridge"

echo "=== ProtonMail Bridge Configuration ==="
echo "Email: $EMAIL"
echo "Config directory: $CONFIG_DIR"
echo ""

# Check if bridge is running
if ! pgrep -f protonmail-bridge > /dev/null; then
    echo "Starting ProtonMail Bridge..."
    ./start_protonmail_bridge.sh
    sleep 5
fi

echo "Bridge should now be running on:"
echo "IMAP: localhost:1143 (with STARTTLS)"
echo "SMTP: localhost:1025 (with STARTTLS)"
echo ""
echo "Next steps:"
echo "1. Login to your ProtonMail account in the bridge"
echo "2. Note down the generated bridge password"
echo "3. Update your .env file with the bridge credentials"
echo ""
echo "To login via CLI (if available):"
echo "protonmail-bridge --cli"
EOF

chmod +x "$HOME/configure_protonmail_bridge.sh"

# Enable and start the service
log "Enabling ProtonMail Bridge service..."
sudo systemctl daemon-reload
sudo systemctl enable protonmail-bridge

# Create bridge password retrieval script
cat > "$HOME/get_bridge_password.sh" << 'EOF'
#!/bin/bash

# Script to retrieve ProtonMail Bridge password
# The bridge generates a unique password for IMAP/SMTP access

CONFIG_DIR="$HOME/.config/protonmail/bridge"
BRIDGE_LOG="/var/log/protonmail-bridge.log"

echo "=== ProtonMail Bridge Password Retrieval ==="
echo ""

if [ -f "$CONFIG_DIR/bridge_password.txt" ]; then
    echo "Bridge password found:"
    cat "$CONFIG_DIR/bridge_password.txt"
else
    echo "Bridge password not found in config directory."
    echo "Please check the bridge logs or use the bridge CLI:"
    echo ""
    echo "journalctl -u protonmail-bridge -f"
    echo ""
    echo "Or start bridge interactively:"
    echo "protonmail-bridge"
fi
EOF

chmod +x "$HOME/get_bridge_password.sh"

success "ProtonMail Bridge installation completed!"

log "Installation summary:"
log "- Bridge binary: /usr/local/bin/protonmail-bridge"
log "- Config directory: $BRIDGE_CONFIG_DIR"
log "- Systemd service: protonmail-bridge.service"
log "- Startup script: $HOME/start_protonmail_bridge.sh"
log "- Configuration script: $HOME/configure_protonmail_bridge.sh"
log ""
log "Next steps:"
log "1. Run: ./configure_protonmail_bridge.sh"
log "2. Login to your ProtonMail account"
log "3. Retrieve bridge password with: ./get_bridge_password.sh"
log "4. Update .env file with bridge credentials"

echo ""
echo "🎉 Installation completed! Check $LOG_FILE for detailed logs."
