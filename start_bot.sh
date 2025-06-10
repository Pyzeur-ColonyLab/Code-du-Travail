#!/bin/bash

# Script de démarrage pour le bot Telegram Code du Travail
# Usage: ./start_bot.sh [--background]

set -e

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$BOT_DIR/venv"
LOG_FILE="$BOT_DIR/bot.log"
PID_FILE="$BOT_DIR/bot.pid"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
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
            print_warning "Le bot est déjà en cours d'exécution (PID: $PID)"
            echo "Pour l'arrêter: ./stop_bot.sh"
            exit 1
        else
            # Supprimer le fichier PID obsolète
            rm -f "$PID_FILE"
        fi
    fi
}

# Vérifier les prérequis
check_prerequisites() {
    print_status "Vérification des prérequis..."
    
    # Vérifier l'environnement virtuel
    if [ ! -d "$VENV_DIR" ]; then
        print_error "Environnement virtuel non trouvé. Exécutez d'abord setup.sh"
        exit 1
    fi
    
    # Vérifier le fichier .env
    if [ ! -f "$BOT_DIR/.env" ]; then
        print_error "Fichier .env non trouvé. Copiez .env.example vers .env et configurez-le"
        exit 1
    fi
    
    # Vérifier le token Telegram
    source "$BOT_DIR/.env"
    if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
        print_error "TELEGRAM_BOT_TOKEN non défini dans .env"
        exit 1
    fi
    
    print_status "Tous les prérequis sont satisfaits"
}

# Fonction pour démarrer le bot
start_bot() {
    local background=$1
    
    cd "$BOT_DIR"
    source "$VENV_DIR/bin/activate"
    
    print_status "Démarrage du bot..."
    
    if [ "$background" = "true" ]; then
        # Démarrage en arrière-plan
        nohup python telegram_bot.py > "$LOG_FILE" 2>&1 &
        echo $! > "$PID_FILE"
        print_status "Bot démarré en arrière-plan (PID: $(cat $PID_FILE))"
        print_status "Logs: tail -f $LOG_FILE"
    else
        # Démarrage en avant-plan
        python telegram_bot.py
    fi
}

# Fonction principale
main() {
    echo "🤖 Démarrage du bot Telegram Code du Travail"
    echo "==========================================="
    
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
trap 'echo; print_status "Arrêt du bot..."; exit 0' INT TERM

main "$@"