#!/bin/bash

# Script de nettoyage à distance pour AWS EC2
# Usage: ./clean_remote.sh <instance-ip> <key-file> [--deep]

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
    echo "Usage: $0 <instance-ip> <key-file> [--deep]"
    echo "Exemple: $0 3.15.45.67 ~/.ssh/ma-cle.pem --deep"
    exit 1
fi

INSTANCE_IP=$1
KEY_FILE=$2
DEEP_CLEAN=""

if [ "$3" = "--deep" ]; then
    DEEP_CLEAN="--deep"
fi

# Vérifier que la clé SSH existe
if [ ! -f "$KEY_FILE" ]; then
    print_error "Fichier de clé SSH '$KEY_FILE' non trouvé"
    exit 1
fi

print_header "🧹 Nettoyage à distance de l'instance AWS EC2"
echo "Instance: $INSTANCE_IP"
echo "Clé SSH: $KEY_FILE"
echo "Nettoyage profond: $([ -n "$DEEP_CLEAN" ] && echo "OUI" || echo "NON")"
echo

# Fonction pour exécuter des commandes sur l'instance distante
exec_remote() {
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no ubuntu@"$INSTANCE_IP" "$1"
}

# Fonction pour copier des fichiers vers l'instance
copy_to_remote() {
    scp -i "$KEY_FILE" -o StrictHostKeyChecking=no "$1" ubuntu@"$INSTANCE_IP":"$2"
}

# Test de connexion
print_status "Test de connexion SSH..."
if ! exec_remote "echo 'Connexion SSH réussie'"; then
    print_error "Impossible de se connecter à l'instance EC2"
    exit 1
fi

# Copier le script de nettoyage sur l'instance
print_status "Copie du script de nettoyage..."
copy_to_remote "clean_instance.sh" "/tmp/clean_instance.sh"

# Rendre le script exécutable et l'exécuter
print_status "Exécution du nettoyage sur l'instance..."
exec_remote "chmod +x /tmp/clean_instance.sh && /tmp/clean_instance.sh $DEEP_CLEAN"

# Nettoyer le script temporaire
exec_remote "rm -f /tmp/clean_instance.sh"

print_header "✅ Nettoyage à distance terminé!"
print_status "L'instance $INSTANCE_IP est maintenant propre et prête pour le déploiement"
