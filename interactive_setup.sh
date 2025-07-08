#!/bin/bash

# Interactive Setup Script for Code du Travail AI Assistant on Infomaniak
# This script prompts for all necessary information and runs all commands automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

print_input() {
    echo -e "${CYAN}[INPUT]${NC} $1"
}

# Function to get user input with validation
get_input() {
    local prompt="$1"
    local default="$2"
    local required="$3"
    local input=""
    
    if [ -n "$default" ]; then
        print_input "$prompt (default: $default): "
    else
        print_input "$prompt: "
    fi
    
    read -r input
    
    # Use default if input is empty
    if [ -z "$input" ] && [ -n "$default" ]; then
        input="$default"
    fi
    
    # Validate required input
    if [ "$required" = "true" ] && [ -z "$input" ]; then
        print_error "This field is required!"
        get_input "$prompt" "$default" "$required"
        return
    fi
    
    echo "$input"
}

# Function to confirm action
confirm_action() {
    local message="$1"
    print_input "$message (y/N): "
    read -r response
    if [[ $response =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root"
        print_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
}

# Function to update system
update_system() {
    print_step "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    print_info "System updated successfully"
}

# Function to install essential packages
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
        software-properties-common \
        python3-openstackclient
    print_info "Essential packages installed successfully"
}

# Function to install Docker
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
    
    print_info "Docker installed and configured successfully"
}

# Function to install NVIDIA drivers (if GPU available)
install_nvidia() {
    print_step "Checking for NVIDIA GPU..."
    
    if lspci | grep -i nvidia > /dev/null; then
        print_info "NVIDIA GPU detected!"
        if confirm_action "Do you want to install NVIDIA drivers and Docker runtime?"; then
            print_info "Installing NVIDIA drivers..."
            
            # Add NVIDIA repository
            distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
            curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
            curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
            
            # Install NVIDIA Docker runtime
            sudo apt update
            sudo apt install -y nvidia-docker2
            
            # Restart Docker
            sudo systemctl restart docker
            
            print_info "NVIDIA Docker runtime installed successfully"
        else
            print_info "Skipping NVIDIA installation"
        fi
    else
        print_info "No NVIDIA GPU detected, skipping NVIDIA installation"
    fi
}

# Function to configure Docker
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
  "storage-driver": "overlay2"
}
EOF
    
    # Restart Docker
    sudo systemctl restart docker
    
    print_info "Docker configured successfully"
}

# Function to clone repository
clone_repository() {
    print_step "Cloning Code du Travail repository..."
    
    if [ -d "Code-du-Travail" ]; then
        print_warning "Code-du-Travail directory already exists"
        if confirm_action "Do you want to remove the existing directory and clone fresh?"; then
            rm -rf Code-du-Travail
        else
            print_info "Using existing directory"
            cd Code-du-Travail
            return
        fi
    fi
    
    git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
    cd Code-du-Travail
    
    print_info "Repository cloned successfully"
}

# Function to run Debian optimization
run_debian_optimization() {
    print_step "Running Debian optimization..."
    
    if [ -f "debian_optimize.sh" ]; then
        chmod +x debian_optimize.sh
        ./debian_optimize.sh
        print_info "Debian optimization completed"
    else
        print_warning "debian_optimize.sh not found, skipping optimization"
    fi
}

# Function to configure environment
configure_environment() {
    print_step "Configuring environment..."
    
    # Get user inputs
    print_info "Please provide the following information:"
    echo
    
    TELEGRAM_BOT_TOKEN=$(get_input "Enter your Telegram Bot Token" "" "true")
    HUGGING_FACE_TOKEN=$(get_input "Enter your Hugging Face Token" "" "true")
    EMAIL_DOMAIN=$(get_input "Enter your email domain (e.g., yourdomain.com)" "" "true")
    EMAIL_ADDRESS=$(get_input "Enter your email address (e.g., bot@yourdomain.com)" "bot@$EMAIL_DOMAIN" "true")
    EMAIL_PASSWORD=$(get_input "Enter your email password" "" "true")
    DEVICE=$(get_input "Enter device type (auto/cpu/cuda)" "auto" "false")
    
    # Create .env file
    cat > .env <<EOF
# Code du Travail AI Assistant - Environment Configuration

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN

# Hugging Face Configuration
HUGGING_FACE_TOKEN=$HUGGING_FACE_TOKEN
MODEL_NAME=Pyzeur/Code-du-Travail-mistral-finetune

# Email Configuration
EMAIL_DOMAIN=$EMAIL_DOMAIN
EMAIL_ADDRESS=$EMAIL_ADDRESS
EMAIL_PASSWORD=$EMAIL_PASSWORD

# Device Configuration
DEVICE=$DEVICE

# Email AI Parameters (for detailed responses)
EMAIL_MAX_TOKENS=1500
EMAIL_TEMPERATURE=0.3
EMAIL_TOP_P=0.95
EMAIL_REPETITION_PENALTY=1.15
EMAIL_CHECK_INTERVAL=30

# Telegram AI Parameters (for conversational responses)
TELEGRAM_MAX_TOKENS=512
TELEGRAM_TEMPERATURE=0.7
TELEGRAM_TOP_P=0.9
TELEGRAM_REPETITION_PENALTY=1.1

# Logging Configuration
LOG_LEVEL=INFO

# Mail Server Configuration
IMAP_HOST=mailserver
IMAP_PORT=993
SMTP_HOST=mailserver
SMTP_PORT=587
EOF
    
    print_info "Environment configuration saved to .env"
}

# Function to setup DNS
setup_dns() {
    print_step "Setting up DNS configuration..."
    
    if confirm_action "Do you want to run DNS optimization for Cloudflare/Infomaniak?"; then
        if [ -f "fix_debian_dns.sh" ]; then
            print_info "Running Debian DNS fix..."
            sudo ./fix_debian_dns.sh
        elif [ -f "fix_ubuntu_dns.sh" ]; then
            print_info "Running Ubuntu DNS fix (fallback)..."
            sudo ./fix_ubuntu_dns.sh
        else
            print_warning "No DNS fix script found"
        fi
    else
        print_info "Skipping DNS optimization"
    fi
}

# Function to create necessary directories
create_directories() {
    print_step "Creating necessary directories..."
    
    mkdir -p docker-data/dms/config
    mkdir -p docker-data/dms/mail-data
    mkdir -p docker-data/dms/mail-state
    mkdir -p docker-data/dms/mail-logs
    mkdir -p logs
    mkdir -p cache
    
    print_info "Directories created successfully"
}

# Function to set permissions
set_permissions() {
    print_step "Setting proper permissions..."
    
    chmod +x *.sh
    
    print_info "Permissions set successfully"
}

# Function to test Docker installation
test_docker() {
    print_step "Testing Docker installation..."
    
    # Test basic Docker
    docker run --rm hello-world
    
    # Test NVIDIA Docker if available
    if command -v nvidia-smi > /dev/null; then
        print_info "Testing NVIDIA Docker support..."
        docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
    fi
    
    print_info "Docker test completed successfully"
}

# Function to start services
start_services() {
    print_step "Starting services..."
    
    if [ -f "start_mailserver_bot.sh" ]; then
        chmod +x start_mailserver_bot.sh
        ./start_mailserver_bot.sh start
        print_info "Services started successfully"
    else
        print_error "start_mailserver_bot.sh not found"
        return 1
    fi
}

# Function to setup email accounts
setup_email_accounts() {
    print_step "Setting up email accounts..."
    
    if confirm_action "Do you want to setup email accounts now?"; then
        if [ -f "start_mailserver_bot.sh" ]; then
            ./start_mailserver_bot.sh setup
            print_info "Email accounts setup completed"
        else
            print_error "start_mailserver_bot.sh not found"
        fi
    else
        print_info "Skipping email account setup"
    fi
}

# Function to show final status
show_final_status() {
    print_step "Final Status Check"
    
    echo
    print_info "Checking service status..."
    docker ps
    
    echo
    print_info "Checking Docker Compose status..."
    docker-compose ps
    
    echo
    print_info "Setup completed successfully!"
    echo
    print_info "Next steps:"
    print_info "1. Logout and login again for Docker group changes to take effect"
    print_info "2. Check service logs: ./start_mailserver_bot.sh logs"
    print_info "3. Monitor system: htop"
    print_info "4. Test email connectivity"
    echo
    print_info "For troubleshooting, see README.md and DEBIAN_SETUP.md"
    echo
    print_info "Your Code du Travail AI Assistant is now running!"
}

# Function to show help
show_help() {
    echo "Interactive Setup Script for Code du Travail AI Assistant"
    echo "========================================================"
    echo
    echo "This script will:"
    echo "1. Update system packages"
    echo "2. Install essential packages and Docker"
    echo "3. Install NVIDIA drivers (if GPU available)"
    echo "4. Clone the repository"
    echo "5. Configure environment"
    echo "6. Setup DNS optimization"
    echo "7. Start all services"
    echo "8. Setup email accounts"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --help, -h     Show this help message"
    echo "  --skip-dns     Skip DNS optimization"
    echo "  --skip-nvidia  Skip NVIDIA installation"
    echo "  --skip-email   Skip email account setup"
    echo
}

# Parse command line arguments
SKIP_DNS=false
SKIP_NVIDIA=false
SKIP_EMAIL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_help
            exit 0
            ;;
        --skip-dns)
            SKIP_DNS=true
            shift
            ;;
        --skip-nvidia)
            SKIP_NVIDIA=true
            shift
            ;;
        --skip-email)
            SKIP_EMAIL=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Main setup function
main() {
    print_info "Interactive Setup for Code du Travail AI Assistant"
    print_info "=================================================="
    echo
    
    # Check if running as root
    check_root
    
    # Confirm start
    if ! confirm_action "Do you want to start the interactive setup?"; then
        print_info "Setup cancelled"
        exit 0
    fi
    
    # Run setup steps
    update_system
    install_packages
    install_docker
    
    if [ "$SKIP_NVIDIA" = false ]; then
        install_nvidia
    fi
    
    configure_docker
    clone_repository
    run_debian_optimization
    configure_environment
    
    if [ "$SKIP_DNS" = false ]; then
        setup_dns
    fi
    
    create_directories
    set_permissions
    test_docker
    start_services
    
    if [ "$SKIP_EMAIL" = false ]; then
        setup_email_accounts
    fi
    
    show_final_status
}

# Run main function
main 