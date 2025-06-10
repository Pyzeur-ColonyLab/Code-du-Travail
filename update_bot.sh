#!/bin/bash

# Script de mise à jour du bot Telegram Code du Travail

set -e

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$BOT_DIR/backup_$(date +%Y%m%d_%H%M%S)"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

echo "🔄 Mise à jour du bot Telegram Code du Travail"
echo "============================================="

# Vérifier si on est dans le bon répertoire
if [ ! -f "telegram_bot.py" ]; then
    print_error "Impossible de trouver telegram_bot.py. Êtes-vous dans le bon répertoire?"
    exit 1
fi

# Vérifier si le bot est en cours d'exécution
PID_FILE="$BOT_DIR/bot.pid"
BOT_RUNNING=false

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        BOT_RUNNING=true
        print_warning "Bot en cours d'exécution (PID: $PID)"
    fi
fi

# Créer une sauvegarde
print_status "Création d'une sauvegarde..."
mkdir -p "$BACKUP_DIR"
cp -r .env* *.log "$BACKUP_DIR/" 2>/dev/null || true
print_status "Sauvegarde créée dans: $BACKUP_DIR"

# Arrêter le bot si nécessaire
if [ "$BOT_RUNNING" = true ]; then
    print_status "Arrêt du bot..."
    ./stop_bot.sh
    sleep 2
fi

# Mettre à jour depuis Git
print_status "Mise à jour depuis Git..."
if git pull origin main; then
    print_status "Code mis à jour avec succès"
else
    print_error "Erreur lors de la mise à jour Git"
    if [ "$BOT_RUNNING" = true ]; then
        print_status "Redémarrage du bot avec l'ancienne version..."
        ./start_bot.sh --background
    fi
    exit 1
fi

# Mettre à jour les dépendances Python
print_status "Mise à jour des dépendances Python..."
if [ -d "venv" ]; then
    source venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt --upgrade
else
    print_error "Environnement virtuel non trouvé. Exécutez setup.sh"
    exit 1
fi

# Vérifier la configuration
print_status "Vérification de la configuration..."
if python run.py --check; then
    print_status "Configuration vérifiée"
else
    print_error "Problème de configuration détecté"
    exit 1
fi

# Redémarrer le bot si il était en cours d'exécution
if [ "$BOT_RUNNING" = true ]; then
    print_status "Redémarrage du bot..."
    ./start_bot.sh --background
    sleep 3
    
    # Vérifier que le bot a redémarré
    if ./status_bot.sh | grep -q "Bot en cours d'exécution"; then
        print_status "Bot redémarré avec succès"
    else
        print_error "Problème lors du redémarrage"
        print_status "Vérifiez les logs: tail -f bot.log"
    fi
fi

print_header "Mise à jour terminée!"
print_status "Sauvegarde disponible dans: $BACKUP_DIR"
print_status "Statut du bot: ./status_bot.sh"
print_status "Logs: tail -f bot.log"
