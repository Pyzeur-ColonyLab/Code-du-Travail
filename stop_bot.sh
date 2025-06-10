#!/bin/bash

# Script d'arrêt pour le bot Telegram Code du Travail

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$BOT_DIR/bot.pid"

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

echo "🛑 Arrêt du bot Telegram Code du Travail"
echo "======================================="

if [ ! -f "$PID_FILE" ]; then
    print_warning "Aucun fichier PID trouvé. Le bot n'est peut-être pas en cours d'exécution."
    exit 0
fi

PID=$(cat "$PID_FILE")

if ! ps -p $PID > /dev/null 2>&1; then
    print_warning "Le processus PID $PID n'est pas en cours d'exécution."
    rm -f "$PID_FILE"
    exit 0
fi

print_status "Arrêt du bot (PID: $PID)..."

# Tentative d'arrêt gracieux
kill -TERM $PID

# Attendre jusqu'à 10 secondes pour l'arrêt
for i in {1..10}; do
    if ! ps -p $PID > /dev/null 2>&1; then
        print_status "Bot arrêté avec succès"
        rm -f "$PID_FILE"
        exit 0
    fi
    sleep 1
done

# Si l'arrêt gracieux a échoué, forcer l'arrêt
print_warning "Arrêt gracieux échoué, arrêt forcé..."
kill -KILL $PID

if ! ps -p $PID > /dev/null 2>&1; then
    print_status "Bot arrêté de force"
    rm -f "$PID_FILE"
else
    print_error "Impossible d'arrêter le bot"
    exit 1
fi