#!/bin/bash

# Debian 11 (Bullseye) Setup Script for Code du Travail AI Assistant
# This script sets up the complete environment on Debian 11

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_info "Debian 11 (Bullseye) Setup for Code du Travail AI Assistant"
print_info "=========================================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    print_info "Please run as a regular user with sudo privileges"
    exit 1
fi

# Check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        print_error ".env file not found!"
        print_info "Please create .env file with your configuration:"
        echo ""
        echo "TELEGRAM_BOT_TOKEN=your_telegram_token"
        echo "HUGGING_FACE_TOKEN=your_hf_token"
        echo "EMAIL_DOMAIN=yourdomain.com"
        echo "EMAIL_ADDRESS=bot@yourdomain.com"
        echo "EMAIL_PASSWORD=your_email_password"
        echo ""
        exit 1
    fi
    print_info ".env file found"
}

# Update system packages
update_system() {
    print_step "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    print_info "System updated"
}

# Install essential packages
install_packages() {
    print_step "Installing essential packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        htop \
        iotop \
        nload \
        net-tools \
        dnsutils \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common
    print_info "Essential packages installed"
}

# Install Docker
install_docker() {
    print_step "Installing Docker..."
    
    # Remove old versions
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_info "Docker installed and configured"
}

# Install NVIDIA drivers (if GPU available)
install_nvidia() {
    print_step "Checking for NVIDIA GPU..."
    
    if lspci | grep -i nvidia > /dev/null; then
        print_info "NVIDIA GPU detected, installing drivers..."
        
        # Add NVIDIA repository
        distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
        curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
        curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
        
        # Install NVIDIA Docker runtime
        sudo apt update
        sudo apt install -y nvidia-docker2
        
        # Restart Docker
        sudo systemctl restart docker
        
        print_info "NVIDIA Docker runtime installed"
    else
        print_info "No NVIDIA GPU detected, skipping NVIDIA installation"
    fi
}

# Configure Docker
configure_docker() {
    print_step "Configuring Docker..."
    
    # Create Docker daemon configuration
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "dns": ["1.1.1.1", "1.0.0.1", "8.8.8.8"],
  "dns-opts": ["timeout:2", "attempts:3"],
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "default-runtime": "nvidia"
}
EOF
    
    # Restart Docker
    sudo systemctl restart docker
    
    print_info "Docker configured"
}

# Create necessary directories
create_directories() {
    print_step "Creating necessary directories..."
    
    mkdir -p docker-data/dms/config
    mkdir -p docker-data/dms/mail-data
    mkdir -p docker-data/dms/mail-state
    mkdir -p docker-data/dms/mail-logs
    mkdir -p logs
    mkdir -p cache
    
    print_info "Directories created"
}

# Set proper permissions
set_permissions() {
    print_step "Setting proper permissions..."
    
    chmod +x *.sh
    
    print_info "Permissions set"
}

# Optimize system for AI workloads
optimize_system() {
    print_step "Optimizing system for AI workloads..."
    
    # Increase file descriptor limits
    echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
    
    # Optimize kernel parameters
    echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
    echo "vm.dirty_ratio=15" | sudo tee -a /etc/sysctl.conf
    echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
    
    # Create swap file if needed
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 4G /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
    fi
    
    print_info "System optimized"
}

# Test Docker installation
test_docker() {
    print_step "Testing Docker installation..."
    
    # Test basic Docker
    docker run --rm hello-world
    
    # Test NVIDIA Docker if available
    if command -v nvidia-smi > /dev/null; then
        docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
    fi
    
    print_info "Docker test completed"
}

# Setup DNS
setup_dns() {
    print_step "Setting up DNS configuration..."
    
    if [ -f fix_debian_dns.sh ]; then
        print_info "Running Debian DNS fix..."
        ./fix_debian_dns.sh
    else
        print_warning "fix_debian_dns.sh not found, DNS setup skipped"
    fi
}

# Main setup function
main() {
    print_info "Starting Debian 11 setup..."
    
    check_env
    update_system
    install_packages
    install_docker
    install_nvidia
    configure_docker
    create_directories
    set_permissions
    optimize_system
    test_docker
    setup_dns
    
    print_info "Setup completed successfully!"
    print_info ""
    print_info "Next steps:"
    print_info "1. Logout and login again for Docker group changes to take effect"
    print_info "2. Configure your .env file with your settings"
    print_info "3. Start the services: ./start_mailserver_bot.sh start"
    print_info "4. Setup email accounts: ./start_mailserver_bot.sh setup"
    print_info ""
    print_info "For troubleshooting, see README.md"
}

# Run main function
main 