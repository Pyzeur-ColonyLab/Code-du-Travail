#!/bin/bash

# Script de déploiement pour AWS EC2
# Usage: ./deploy_aws.sh [instance-ip] [key-file]

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

# Vérifier les arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <instance-ip> <key-file> [telegram-token]"
    echo "Exemple: $0 3.15.45.67 ~/.ssh/my-key.pem 123456:ABC-DEF..."
    exit 1
fi

INSTANCE_IP=$1
KEY_FILE=$2
TELEGRAM_TOKEN=${3:-}

# Vérifier que la clé SSH existe
if [ ! -f "$KEY_FILE" ]; then
    print_error "Fichier de clé SSH '$KEY_FILE' non trouvé"
    exit 1
fi

print_header "Déploiement du bot Code du Travail sur AWS EC2"
echo "Instance: $INSTANCE_IP"
echo "Clé SSH: $KEY_FILE"
echo

# Fonction pour exécuter des commandes sur l'instance distante
exec_remote() {
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$INSTANCE_IP" "$1"
}

# Fonction pour copier des fichiers
copy_to_remote() {
    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r "$1" ubuntu@"$INSTANCE_IP":"$2"
}

print_status "Test de connexion SSH..."
if ! exec_remote "echo 'Connexion SSH réussie'"; then
    print_error "Impossible de se connecter à l'instance EC2"
    exit 1
fi

print_status "Mise à jour du système..."
exec_remote "sudo apt update && sudo apt upgrade -y"

print_status "Installation des dépendances système..."
exec_remote "sudo apt install -y python3 python3-pip python3-venv git wget curl htop tmux build-essential"

print_status "Clonage du repository..."
exec_remote "git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git || (cd Code-du-Travail && git pull)"

print_status "Exécution du script d'installation..."
exec_remote "cd Code-du-Travail && chmod +x setup.sh && ./setup.sh"

# Configuration du token Telegram si fourni
if [ -n "$TELEGRAM_TOKEN" ]; then
    print_status "Configuration du token Telegram..."
    exec_remote "cd Code-du-Travail && echo 'TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN' > .env"
else
    print_warning "Token Telegram non fourni. Vous devrez le configurer manuellement."
fi

print_status "Configuration des permissions..."
exec_remote "cd Code-du-Travail && chmod +x *.sh && chmod +x *.py"

print_status "Test de l'installation..."
if exec_remote "cd Code-du-Travail && source venv/bin/activate && python run.py --check"; then
    print_status "Installation vérifiée avec succès!"
else
    print_warning "Vérification échouée, mais l'installation pourrait être fonctionnelle"
fi

print_header "Déploiement terminé!"
echo
print_status "Prochaines étapes:"
echo
echo "1. Se connecter à l'instance:"
echo "   ssh -i $KEY_FILE ubuntu@$INSTANCE_IP"
echo
echo "2. Aller dans le répertoire du projet:"
echo "   cd Code-du-Travail"
echo
echo "3. Configurer le token Telegram (si pas déjà fait):"
echo "   nano .env"
echo "   # Ajouter: TELEGRAM_BOT_TOKEN=votre_token"
echo
echo "4. Démarrer le bot:"
echo "   ./start_bot.sh --background"
echo
echo "5. Vérifier le statut:"
echo "   ./status_bot.sh"
echo
echo "6. Voir les logs:"
echo "   tail -f bot.log"
echo
print_status "Le bot est prêt à être utilisé!"
