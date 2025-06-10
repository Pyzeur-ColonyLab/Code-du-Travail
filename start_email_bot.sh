#!/bin/bash

# Script de démarrage pour le bot Email Code du Travail
# Usage: ./start_email_bot.sh [--background]

set -e

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$BOT_DIR/venv"
LOG_FILE="$BOT_DIR/email_bot.log"
PID_FILE="$BOT_DIR/email_bot.pid"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier si le bot est déjà en cours d'exécution
check_running() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            print_warning "Le bot email est déjà en cours d'exécution (PID: $PID)"
            echo "Pour l'arrêter: ./stop_email_bot.sh"
            exit 1
        else
            rm -f "$PID_FILE"
        fi
    fi
}

# Vérifier les prérequis
check_prerequisites() {
    print_status "Vérification des prérequis..."
    
    if [ ! -d "$VENV_DIR" ]; then
        print_error "Environnement virtuel non trouvé. Exécutez d'abord setup.sh"
        exit 1
    fi
    
    if [ ! -f "$BOT_DIR/.env" ]; then
        print_error "Fichier .env non trouvé. Configurez EMAIL_ADDRESS et EMAIL_PASSWORD"
        exit 1
    fi
    
    # Vérifier la configuration email
    source "$BOT_DIR/.env"
    if [ -z "$EMAIL_ADDRESS" ]; then
        print_error "EMAIL_ADDRESS non défini dans .env"
        exit 1
    fi
    
    if [ -z "$EMAIL_PASSWORD" ]; then
        print_error "EMAIL_PASSWORD non défini dans .env"
        exit 1
    fi
    
    print_status "Tous les prérequis sont satisfaits"
}

# Fonction pour démarrer le bot
start_bot() {
    local background=$1
    
    cd "$BOT_DIR"
    source "$VENV_DIR/bin/activate"
    
    print_status "Démarrage du bot email..."
    
    if [ "$background" = "true" ]; then
        nohup python email_bot.py > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        print_status "Bot email démarré en arrière-plan (PID: $(cat $PID_FILE))"
        print_status "Logs: tail -f $LOG_FILE"
    else
        python email_bot.py
    fi
}

# Fonction principale
main() {
    echo "📧 Démarrage du bot Email Code du Travail"
    echo "========================================"
    
    # Vérifier les arguments
    background=false
    if [ "$1" = "--background" ] || [ "$1" = "-b" ]; then
        background=true
    fi
    
    check_running
    check_prerequisites
    start_bot $background
}

# Gestion des signaux pour un arrêt propre
trap 'echo; print_status "Arrêt du bot email..."; exit 0' INT TERM

main "$@"
