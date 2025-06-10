#!/bin/bash

# Script de statut pour le bot Telegram Code du Travail

BOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$BOT_DIR/bot.pid"
LOG_FILE="$BOT_DIR/bot.log"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "📊 Statut du bot Telegram Code du Travail"
echo "========================================"

# Vérifier le statut du processus
print_header "État du processus"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p $PID > /dev/null 2>&1; then
        print_status "Bot en cours d'exécution (PID: $PID)"
        
        # Informations sur le processus
        echo "Temps de fonctionnement: $(ps -o etime= -p $PID | tr -d ' ')"
        echo "Utilisation mémoire: $(ps -o rss= -p $PID | awk '{print $1/1024 " MB"}')"
        echo "Utilisation CPU: $(ps -o %cpu= -p $PID | tr -d ' ')%"
    else
        print_error "Processus PID $PID non trouvé (bot arrêté de manière inattendue)"
        rm -f "$PID_FILE"
    fi
else
    print_warning "Aucun fichier PID trouvé (bot non démarré)"
fi

# Vérifier les fichiers de configuration
print_header "Configuration"
if [ -f "$BOT_DIR/.env" ]; then
    print_status "Fichier .env présent"
    
    # Vérifier le token (sans l'afficher)
    source "$BOT_DIR/.env"
    if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
        print_status "Token Telegram configuré"
    else
        print_error "Token Telegram manquant"
    fi
else
    print_error "Fichier .env manquant"
fi

# Vérifier l'environnement virtuel
if [ -d "$BOT_DIR/venv" ]; then
    print_status "Environnement virtuel présent"
else
    print_error "Environnement virtuel manquant"
fi

# Vérifier les logs
print_header "Logs"
if [ -f "$LOG_FILE" ]; then
    log_size=$(du -h "$LOG_FILE" | cut -f1)
    log_lines=$(wc -l < "$LOG_FILE")
    print_status "Fichier log présent ($log_size, $log_lines lignes)"
    
    echo
    echo "Dernières lignes du log:"
    echo "------------------------"
    tail -n 5 "$LOG_FILE" 2>/dev/null || echo "Impossible de lire le fichier log"
else
    print_warning "Aucun fichier log trouvé"
fi

# Informations système
print_header "Système"
echo "Espace disque disponible: $(df -h . | tail -1 | awk '{print $4}')"
echo "Charge système: $(uptime | awk -F'load average:' '{print $2}')"
echo "Mémoire disponible: $(free -h 2>/dev/null | awk '/^Mem:/ {print $7}' || echo 'N/A')"

# Vérifier CUDA si disponible
if command -v nvidia-smi &> /dev/null; then
    print_header "GPU (NVIDIA)"
    nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits | \
    while IFS=, read -r name mem_used mem_total gpu_util; do
        echo "GPU: $name"
        echo "Mémoire GPU: ${mem_used}MB / ${mem_total}MB"
        echo "Utilisation GPU: ${gpu_util}%"
    done
fi

echo
echo "Pour voir les logs en temps réel: tail -f $LOG_FILE"
echo "Pour démarrer le bot: ./start_bot.sh"
echo "Pour arrêter le bot: ./stop_bot.sh"