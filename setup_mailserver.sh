#!/bin/bash

# Setup script for docker-mailserver
# This script helps manage email accounts and aliases

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

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
DMS_CONFIG_DIR="$SCRIPT_DIR/docker-data/dms/config"

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose not found. Please install Docker Compose."
        exit 1
    fi
}

# Function to safely load environment variables
load_env_file() {
    if [ ! -f "$SCRIPT_DIR/.env" ]; then
        print_error ".env file not found. Please create one based on .env.example"
        exit 1
    fi
    
    # Load environment variables safely by reading line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Check if line contains an assignment
        if [[ "$line" =~ ^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*= ]]; then
            # Export the variable safely
            export "$line"
        fi
    done < "$SCRIPT_DIR/.env"
}

# Function to check if .env file exists and validate required variables
check_env_file() {
    print_step "Loading environment configuration..."
    
    # Load environment variables safely
    load_env_file
    
    if [ -z "$EMAIL_DOMAIN" ]; then
        print_error "EMAIL_DOMAIN not set in .env file"
        exit 1
    fi
    
    if [ -z "$EMAIL_ADDRESS" ]; then
        print_error "EMAIL_ADDRESS not set in .env file"
        exit 1
    fi
    
    if [ -z "$EMAIL_PASSWORD" ]; then
        print_error "EMAIL_PASSWORD not set in .env file"
        exit 1
    fi
    
    print_info "Configuration validated"
    print_info "Domain: $EMAIL_DOMAIN"
    print_info "Email: $EMAIL_ADDRESS"
}

# Function to create email account
create_email_account() {
    local email="$1"
    local password="$2"
    
    print_info "Creating email account: $email"
    
    # Use docker-mailserver setup script
    $DOCKER_COMPOSE_CMD exec mailserver setup email add "$email" "$password"
    
    if [ $? -eq 0 ]; then
        print_info "Email account created successfully: $email"
    else
        print_error "Failed to create email account: $email"
        exit 1
    fi
}

# Function to list email accounts
list_email_accounts() {
    print_info "Listing email accounts:"
    $DOCKER_COMPOSE_CMD exec mailserver setup email list
}

# Function to create alias
create_alias() {
    local alias="$1"
    local destination="$2"
    
    print_info "Creating alias: $alias -> $destination"
    
    $DOCKER_COMPOSE_CMD exec mailserver setup alias add "$alias" "$destination"
    
    if [ $? -eq 0 ]; then
        print_info "Alias created successfully: $alias -> $destination"
    else
        print_error "Failed to create alias: $alias -> $destination"
        exit 1
    fi
}

# Function to start mailserver
start_mailserver() {
    print_info "Starting docker-mailserver..."
    
    # Create necessary directories
    mkdir -p "$DMS_CONFIG_DIR"
    
    # Start the mailserver service
    $DOCKER_COMPOSE_CMD up -d mailserver
    
    # Wait for mailserver to be ready
    print_info "Waiting for mailserver to be ready..."
    sleep 30
    
    # Check if mailserver is running
    if $DOCKER_COMPOSE_CMD ps | grep -q "mailserver.*Up"; then
        print_info "Mailserver is running"
        return 0
    else
        print_error "Mailserver failed to start"
        return 1
    fi
}

# Function to stop mailserver
stop_mailserver() {
    print_info "Stopping docker-mailserver..."
    $DOCKER_COMPOSE_CMD stop mailserver
}

# Function to setup initial configuration
setup_initial_config() {
    print_info "Setting up initial configuration..."
    
    # Start mailserver if not running
    if ! $DOCKER_COMPOSE_CMD ps | grep -q "mailserver.*Up"; then
        start_mailserver
    fi
    
    # Create main email account
    create_email_account "$EMAIL_ADDRESS" "$EMAIL_PASSWORD"
    
    # Create postmaster account
    create_email_account "postmaster@$EMAIL_DOMAIN" "$EMAIL_PASSWORD"
    
    # Create aliases
    create_alias "admin@$EMAIL_DOMAIN" "$EMAIL_ADDRESS"
    create_alias "support@$EMAIL_DOMAIN" "$EMAIL_ADDRESS"
    create_alias "info@$EMAIL_DOMAIN" "$EMAIL_ADDRESS"
    
    print_info "Initial configuration completed!"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup              Setup initial configuration"
    echo "  start              Start mailserver"
    echo "  stop               Stop mailserver"
    echo "  create-account     Create email account"
    echo "  list-accounts      List email accounts"
    echo "  create-alias       Create email alias"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup                                    # Setup initial configuration"
    echo "  $0 create-account user@domain.com password # Create email account"
    echo "  $0 create-alias alias@domain.com user@domain.com # Create alias"
    echo "  $0 list-accounts                            # List all accounts"
}

# Main function
main() {
    check_docker_compose
    check_env_file
    
    case "${1:-}" in
        setup)
            setup_initial_config
            ;;
        start)
            start_mailserver
            ;;
        stop)
            stop_mailserver
            ;;
        create-account)
            if [ $# -lt 3 ]; then
                print_error "Usage: $0 create-account <email> <password>"
                exit 1
            fi
            create_email_account "$2" "$3"
            ;;
        list-accounts)
            list_email_accounts
            ;;
        create-alias)
            if [ $# -lt 3 ]; then
                print_error "Usage: $0 create-alias <alias> <destination>"
                exit 1
            fi
            create_alias "$2" "$3"
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            print_error "No command provided"
            show_help
            exit 1
            ;;
        *)
            print_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
