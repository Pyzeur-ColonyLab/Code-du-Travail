#!/bin/bash

# Infomaniak Public Cloud Deployment Script for Code du Travail AI Assistant
# This script automates the deployment on Infomaniak instances

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

# Configuration
INSTANCE_NAME="code-du-travail-ai"
FLAVOR="a2-ram4-disk50-perf1"  # 4GB RAM, 50GB disk
IMAGE="Debian 11.5 bullseye"
SECURITY_GROUP="mailserver-sec"
NETWORK="ext-net1"

print_info "Code du Travail AI Assistant - Infomaniak Deployment"
print_info "=================================================="

# Check if openstack client is installed
check_openstack() {
    if ! command -v openstack &> /dev/null; then
        print_error "OpenStack client not found. Please install it first:"
        print_info "sudo apt install python3-openstackclient"
        exit 1
    fi
}

# Check if openrc file exists
check_openrc() {
    if [ ! -f "openrc" ]; then
        print_error "openrc file not found. Please download it from your Infomaniak dashboard."
        print_info "The file should contain your authentication credentials."
        exit 1
    fi
}

# Create security group
create_security_group() {
    print_step "Creating security group for mail server..."
    
    # Check if security group already exists
    if openstack security group show "$SECURITY_GROUP" &> /dev/null; then
        print_info "Security group $SECURITY_GROUP already exists"
        return 0
    fi
    
    # Create security group
    openstack security group create --description "Mail Server Ports for Code du Travail AI" "$SECURITY_GROUP"
    
    # Add rules for mail server
    print_info "Adding security group rules..."
    openstack security group rule create --dst-port 25 --protocol TCP "$SECURITY_GROUP"
    openstack security group rule create --dst-port 587 --protocol TCP "$SECURITY_GROUP"
    openstack security group rule create --dst-port 993 --protocol TCP "$SECURITY_GROUP"
    openstack security group rule create --dst-port 465 --protocol TCP "$SECURITY_GROUP"
    openstack security group rule create --dst-port 22 --protocol TCP "$SECURITY_GROUP"
    openstack security group rule create --dst-port 80 --protocol TCP "$SECURITY_GROUP"
    openstack security group rule create --dst-port 443 --protocol TCP "$SECURITY_GROUP"
    
    print_info "Security group created successfully"
}

# Create SSH key if not exists
create_ssh_key() {
    print_step "Setting up SSH key..."
    
    KEY_NAME="code-du-travail-key"
    
    # Check if key already exists
    if openstack keypair show "$KEY_NAME" &> /dev/null; then
        print_info "SSH key $KEY_NAME already exists"
        return 0
    fi
    
    # Generate SSH key
    if [ ! -f "~/.ssh/id_rsa" ]; then
        print_info "Generating SSH key pair..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    # Import key to OpenStack
    openstack keypair create --public-key ~/.ssh/id_rsa.pub "$KEY_NAME"
    print_info "SSH key created and imported"
}

# Create instance
create_instance() {
    print_step "Creating Infomaniak instance..."
    
    # Check if instance already exists
    if openstack server show "$INSTANCE_NAME" &> /dev/null; then
        print_warning "Instance $INSTANCE_NAME already exists"
        read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Deleting existing instance..."
            openstack server delete "$INSTANCE_NAME"
            sleep 10
        else
            print_info "Using existing instance"
            return 0
        fi
    fi
    
    # Create instance
    print_info "Creating instance with specs:"
    print_info "  Name: $INSTANCE_NAME"
    print_info "  Flavor: $FLAVOR"
    print_info "  Image: $IMAGE"
    print_info "  Security Group: $SECURITY_GROUP"
    print_info "  Network: $NETWORK"
    
    openstack server create \
        --flavor "$FLAVOR" \
        --image "$IMAGE" \
        --security-group "$SECURITY_GROUP" \
        --network "$NETWORK" \
        --key-name "code-du-travail-key" \
        --wait \
        "$INSTANCE_NAME"
    
    print_info "Instance created successfully"
}

# Get instance IP
get_instance_ip() {
    print_step "Getting instance IP address..."
    
    # Wait for instance to be active
    print_info "Waiting for instance to be ready..."
    openstack server wait --timeout 300 "$INSTANCE_NAME"
    
    # Get floating IP
    FLOATING_IP=$(openstack server show "$INSTANCE_NAME" -f value -c addresses | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    
    if [ -z "$FLOATING_IP" ]; then
        print_error "Could not get instance IP address"
        exit 1
    fi
    
    print_info "Instance IP: $FLOATING_IP"
    echo "$FLOATING_IP" > instance_ip.txt
}

# Wait for SSH to be available
wait_for_ssh() {
    print_step "Waiting for SSH to be available..."
    
    FLOATING_IP=$(cat instance_ip.txt)
    
    until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 debian@"$FLOATING_IP" "echo 'SSH connection successful'" &> /dev/null; do
        print_info "Waiting for SSH connection..."
        sleep 10
    done
    
    print_info "SSH connection established"
}

# Deploy application
deploy_application() {
    print_step "Deploying application to instance..."
    
    FLOATING_IP=$(cat instance_ip.txt)
    
    # Create deployment script
    cat > deploy_app.sh << 'EOF'
#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER

# Install Git
sudo apt install git -y

# Clone repository
git clone https://github.com/yourusername/code-du-travail-ai.git
cd code-du-travail-ai

# Create necessary directories
mkdir -p docker-data/dms/config
mkdir -p docker-data/dms/mail-data
mkdir -p docker-data/dms/mail-state
mkdir -p docker-data/dms/mail-logs
mkdir -p logs

# Make scripts executable
chmod +x *.sh

# Run Debian optimization if available
if [ -f debian_optimize.sh ]; then
    echo "Running Debian optimization..."
    ./debian_optimize.sh
fi

# Run DNS fix if available
if [ -f fix_debian_dns.sh ]; then
    echo "Running Debian DNS fix..."
    ./fix_debian_dns.sh
fi

echo "Application deployment completed!"
EOF
    
    # Copy deployment script to instance
    scp -o StrictHostKeyChecking=no deploy_app.sh debian@"$FLOATING_IP":~/
    
    # Execute deployment script
    ssh -o StrictHostKeyChecking=no debian@"$FLOATING_IP" "chmod +x deploy_app.sh && ./deploy_app.sh"
    
    print_info "Application deployed successfully"
}

# Setup DNS (optional)
setup_dns() {
    print_step "DNS Setup Instructions"
    
    FLOATING_IP=$(cat instance_ip.txt)
    
    print_info "Please configure your DNS records:"
    echo
    print_info "A Record:"
    print_info "  mail.yourdomain.com.    IN  A       $FLOATING_IP"
    echo
    print_info "MX Record:"
    print_info "  yourdomain.com.         IN  MX  10  mail.yourdomain.com."
    echo
    print_info "SPF Record:"
    print_info "  yourdomain.com.         IN  TXT     \"v=spf1 mx ~all\""
    echo
    print_warning "Please update yourdomain.com with your actual domain"
}

# Show connection info
show_connection_info() {
    print_step "Connection Information"
    
    FLOATING_IP=$(cat instance_ip.txt)
    
    print_info "Instance Details:"
    print_info "  Name: $INSTANCE_NAME"
    print_info "  IP: $FLOATING_IP"
    print_info "  SSH: ssh debian@$FLOATING_IP"
    echo
    print_info "Next Steps:"
    print_info "1. SSH into the instance: ssh debian@$FLOATING_IP"
    print_info "2. Configure your .env file with your settings"
    print_info "3. Start the services: ./start_mailserver_bot.sh start"
    print_info "4. Setup email accounts: ./start_mailserver_bot.sh setup"
    echo
    print_info "For detailed setup instructions, see DOCKER_MAILSERVER_SETUP.md"
}

# Main deployment function
main() {
    print_info "Starting Infomaniak deployment..."
    
    # Check prerequisites
    check_openstack
    check_openrc
    
    # Source openrc file
    source openrc
    
    # Deploy infrastructure
    create_security_group
    create_ssh_key
    create_instance
    get_instance_ip
    wait_for_ssh
    deploy_application
    
    # Show results
    setup_dns
    show_connection_info
    
    print_info "Deployment completed successfully!"
    print_info "Instance IP saved to instance_ip.txt"
}

# Show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  deploy    Deploy the complete application (default)"
    echo "  clean     Clean up resources"
    echo "  status    Show deployment status"
    echo "  help      Show this help message"
    echo ""
    echo "Prerequisites:"
    echo "  - OpenStack client installed"
    echo "  - openrc file in current directory"
    echo "  - SSH key pair (~/.ssh/id_rsa)"
}

# Clean up resources
cleanup() {
    print_step "Cleaning up resources..."
    
    source openrc
    
    # Delete instance
    if openstack server show "$INSTANCE_NAME" &> /dev/null; then
        print_info "Deleting instance $INSTANCE_NAME..."
        openstack server delete "$INSTANCE_NAME"
    fi
    
    # Delete security group
    if openstack security group show "$SECURITY_GROUP" &> /dev/null; then
        print_info "Deleting security group $SECURITY_GROUP..."
        openstack security group delete "$SECURITY_GROUP"
    fi
    
    # Delete SSH key
    if openstack keypair show "code-du-travail-key" &> /dev/null; then
        print_info "Deleting SSH key code-du-travail-key..."
        openstack keypair delete "code-du-travail-key"
    fi
    
    # Remove local files
    rm -f instance_ip.txt deploy_app.sh
    
    print_info "Cleanup completed"
}

# Show status
show_status() {
    print_step "Deployment Status"
    
    source openrc
    
    # Check instance
    if openstack server show "$INSTANCE_NAME" &> /dev/null; then
        print_info "Instance $INSTANCE_NAME: EXISTS"
        openstack server show "$INSTANCE_NAME" -f value -c status -c addresses
    else
        print_warning "Instance $INSTANCE_NAME: NOT FOUND"
    fi
    
    # Check security group
    if openstack security group show "$SECURITY_GROUP" &> /dev/null; then
        print_info "Security group $SECURITY_GROUP: EXISTS"
    else
        print_warning "Security group $SECURITY_GROUP: NOT FOUND"
    fi
    
    # Check SSH key
    if openstack keypair show "code-du-travail-key" &> /dev/null; then
        print_info "SSH key code-du-travail-key: EXISTS"
    else
        print_warning "SSH key code-du-travail-key: NOT FOUND"
    fi
}

# Parse command line arguments
case "${1:-deploy}" in
    deploy)
        main
        ;;
    clean)
        cleanup
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 