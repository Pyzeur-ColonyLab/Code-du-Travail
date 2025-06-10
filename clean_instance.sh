#!/bin/bash

# Script de nettoyage complet pour instance AWS EC2
# Usage: ./clean_instance.sh [--deep]

set -e

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

# Vérifier si on veut un nettoyage profond
DEEP_CLEAN=false
if [ "$1" = "--deep" ]; then
    DEEP_CLEAN=true
fi

print_header "🧹 Nettoyage de l'instance AWS EC2"
echo "Nettoyage profond: $DEEP_CLEAN"
echo

# 1. Arrêter tous les services liés au bot
print_status "Arrêt des services du bot..."

# Arrêter le service systemd s'il existe
if systemctl is-active --quiet code-du-travail-bot.service 2>/dev/null; then
    print_status "Arrêt du service systemd..."
    sudo systemctl stop code-du-travail-bot.service
    sudo systemctl disable code-du-travail-bot.service
fi

# Tuer tous les processus Python liés au bot
print_status "Arrêt des processus Python..."
pkill -f "telegram_bot.py" 2>/dev/null || true
pkill -f "python.*bot" 2>/dev/null || true

# Attendre que les processus se terminent
sleep 2

# 2. Nettoyer les fichiers du projet existant
print_status "Suppression des anciens fichiers du projet..."

# Supprimer le répertoire du projet s'il existe
if [ -d "/home/ubuntu/Code-du-Travail" ]; then
    rm -rf /home/ubuntu/Code-du-Travail
    print_status "Ancien projet supprimé"
fi

# Supprimer les liens symboliques ou copies
rm -f /usr/local/bin/code-du-travail* 2>/dev/null || true

# 3. Nettoyer les services systemd
print_status "Nettoyage des services systemd..."
if [ -f "/etc/systemd/system/code-du-travail-bot.service" ]; then
    sudo rm -f /etc/systemd/system/code-du-travail-bot.service
    sudo systemctl daemon-reload
    print_status "Service systemd supprimé"
fi

# 4. Nettoyer les environnements Python
print_status "Nettoyage des environnements Python..."

# Supprimer les anciens environnements virtuels
find /home/ubuntu -name "venv" -type d -exec rm -rf {} + 2>/dev/null || true
find /home/ubuntu -name ".venv" -type d -exec rm -rf {} + 2>/dev/null || true

# 5. Nettoyer les caches
print_status "Nettoyage des caches..."

# Cache pip
rm -rf /home/ubuntu/.cache/pip/* 2>/dev/null || true

# Cache HuggingFace (important pour les modèles)
rm -rf /home/ubuntu/.cache/huggingface/* 2>/dev/null || true

# Cache PyTorch
rm -rf /home/ubuntu/.cache/torch/* 2>/dev/null || true

# Logs temporaires
rm -f /home/ubuntu/*.log 2>/dev/null || true
rm -f /home/ubuntu/bot.log* 2>/dev/null || true

# 6. Nettoyage système (si nettoyage profond)
if [ "$DEEP_CLEAN" = true ]; then
    print_header "🔄 Nettoyage profond du système..."
    
    # Mettre à jour la liste des paquets
    print_status "Mise à jour de la liste des paquets..."
    sudo apt update
    
    # Supprimer les paquets orphelins
    print_status "Suppression des paquets orphelins..."
    sudo apt autoremove -y
    sudo apt autoclean
    
    # Nettoyer les logs système anciens
    print_status "Nettoyage des logs système..."
    sudo journalctl --vacuum-time=7d
    
    # Nettoyer le cache APT
    print_status "Nettoyage du cache APT..."
    sudo apt clean
    
    # Nettoyer les fichiers temporaires
    print_status "Nettoyage des fichiers temporaires..."
    sudo rm -rf /tmp/* 2>/dev/null || true
    sudo rm -rf /var/tmp/* 2>/dev/null || true
    
    # Nettoyer les anciens kernels (garder les 2 derniers)
    print_status "Nettoyage des anciens kernels..."
    sudo apt autoremove --purge -y 2>/dev/null || true
fi

# 7. Nettoyer Docker (si installé)
if command -v docker &> /dev/null; then
    print_status "Nettoyage Docker..."
    
    # Arrêter tous les conteneurs
    docker stop $(docker ps -aq) 2>/dev/null || true
    
    # Supprimer tous les conteneurs
    docker rm $(docker ps -aq) 2>/dev/null || true
    
    # Supprimer les images non utilisées
    docker image prune -af 2>/dev/null || true
    
    # Supprimer les volumes non utilisés
    docker volume prune -f 2>/dev/null || true
    
    # Supprimer les réseaux non utilisés
    docker network prune -f 2>/dev/null || true
fi

# 8. Vérifier l'espace disque
print_header "💾 Espace disque après nettoyage"
df -h / | tail -1 | awk '{print "Utilisé: " $3 "/" $2 " (" $5 ")"}'

# 9. Vérifier les processus en cours
print_header "🔍 Processus Python en cours"
if pgrep -f python > /dev/null; then
    print_warning "Processus Python encore actifs:"
    ps aux | grep python | grep -v grep
else
    print_status "Aucun processus Python en cours"
fi

# 10. Vérifier les ports en écoute
print_header "🌐 Ports en écoute"
netstat -tuln | grep LISTEN | head -5

# 11. Redémarrer les services essentiels
print_status "Redémarrage des services essentiels..."
sudo systemctl restart ssh

print_header "✅ Nettoyage terminé!"
echo
print_status "L'instance est maintenant prête pour un nouveau déploiement"
print_status "Espace disque libéré visible ci-dessus"
echo
print_status "Prochaines étapes:"
echo "1. Cloner le nouveau repository"
echo "2. Exécuter le script de déploiement"
echo "3. Configurer le token Telegram"
echo
print_warning "Note: Un redémarrage de l'instance peut être recommandé pour une remise à zéro complète"
