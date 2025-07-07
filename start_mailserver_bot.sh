#!/bin/bash

# Start script for Code du Travail AI Bots with Docker-Mailserver
# This script starts both the mailserver and the AI bots

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
    if [ ! -f ".env" ]; then
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
    done < ".env"
}

# Function to check if .env file exists and validate required variables
check_env_file() {
    print_step "Loading environment configuration..."
    
    # Load environment variables safely
    load_env_file
    
    # Check required variables
    if [ -z "$EMAIL_DOMAIN" ]; then
        print_error "EMAIL_DOMAIN not set in .env file"
        exit 1
    fi
    
    if [ -z "$EMAIL_ADDRESS" ]; then
        print_error "EMAIL_ADDRESS not set in .env file"
        exit 1
    fi
    
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        print_error "TELEGRAM_BOT_TOKEN not set in .env file"
        exit 1
    fi
    
    print_info "Configuration validated"
    print_info "Domain: $EMAIL_DOMAIN"
    print_info "Email: $EMAIL_ADDRESS"
}

# Function to create directories
create_directories() {
    print_step "Creating necessary directories..."
    
    mkdir -p docker-data/dms/config
    mkdir -p docker-data/dms/mail-data
    mkdir -p docker-data/dms/mail-state
    mkdir -p docker-data/dms/mail-logs
    mkdir -p logs
    
    print_info "Directories created"
}

# Function to start services
start_services() {
    print_step "Starting Docker services..."
    
    # Start mailserver first
    print_info "Starting docker-mailserver..."
    $DOCKER_COMPOSE_CMD up -d mailserver
    
    # Wait for mailserver to be ready
    print_info "Waiting for mailserver to be ready..."
    sleep 30
    
    # Check if mailserver is running
    if $DOCKER_COMPOSE_CMD ps | grep -q "mailserver.*Up"; then
        print_info "Mailserver is running"
    else
        print_error "Mailserver failed to start"
        exit 1
    fi
    
    # Start the AI bots
    print_info "Starting AI bots..."
    $DOCKER_COMPOSE_CMD up -d telegram-bot
    
    print_info "All services started successfully!"
}

# Function to show logs
show_logs() {
    print_step "Showing logs (Press Ctrl+C to stop)..."
    $DOCKER_COMPOSE_CMD logs -f
}

# Function to show status
show_status() {
    print_step "Showing service status..."
    $DOCKER_COMPOSE_CMD ps
    
    print_step "Showing logs (last 20 lines)..."
    $DOCKER_COMPOSE_CMD logs --tail=20
}

# Function to setup email accounts
setup_email_accounts() {
    print_step "Setting up email accounts..."
    
    # Check if mailserver is running
    if ! $DOCKER_COMPOSE_CMD ps | grep -q "mailserver.*Up"; then
        print_error "Mailserver is not running. Please start services first."
        exit 1
    fi
    
    # Create main email account
    print_info "Creating main email account: $EMAIL_ADDRESS"
    $DOCKER_COMPOSE_CMD exec mailserver setup email add "$EMAIL_ADDRESS" "$EMAIL_PASSWORD"
    
    # Create postmaster account
    print_info "Creating postmaster account: postmaster@$EMAIL_DOMAIN"
    $DOCKER_COMPOSE_CMD exec mailserver setup email add "postmaster@$EMAIL_DOMAIN" "$EMAIL_PASSWORD"
    
    # Create aliases
    print_info "Creating aliases..."
    $DOCKER_COMPOSE_CMD exec mailserver setup alias add "admin@$EMAIL_DOMAIN" "$EMAIL_ADDRESS"
    $DOCKER_COMPOSE_CMD exec mailserver setup alias add "support@$EMAIL_DOMAIN" "$EMAIL_ADDRESS"
    $DOCKER_COMPOSE_CMD exec mailserver setup alias add "info@$EMAIL_DOMAIN" "$EMAIL_ADDRESS"
    
    print_info "Email accounts setup completed!"
}

# Function to show help
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start      Start all services (mailserver + AI bots)"
    echo "  stop       Stop all services"
    echo "  restart    Restart all services"
    echo "  status     Show service status"
    echo "  logs       Show logs (follow mode)"
    echo "  setup      Setup email accounts"
    echo "  help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start               # Start all services"
    echo "  $0 setup               # Setup email accounts"
    echo "  $0 logs                # Show logs"
    echo "  $0 status              # Show status"
}

# Main function
main() {
    print_info "Code du Travail AI Bots with Docker-Mailserver"
    print_info "=============================================="
    
    check_docker_compose
    check_env_file
    create_directories
    
    case "${1:-}" in
        start)
            start_services
            show_status
            ;;
        stop)
            print_step "Stopping services..."
            $DOCKER_COMPOSE_CMD down
            print_info "Services stopped"
            ;;
        restart)
            print_step "Restarting services..."
            $DOCKER_COMPOSE_CMD down
            sleep 2
            start_services
            show_status
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        setup)
            setup_email_accounts
            ;;
        help|--help|-h)
            show_help
            ;;
        "")
            print_info "Starting services by default..."
            start_services
            show_status
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
