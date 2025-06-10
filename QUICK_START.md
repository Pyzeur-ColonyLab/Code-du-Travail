# 🚀 Guide de Démarrage Rapide - Bot Code du Travail

## Installation sur AWS EC2 (Recommandée)

### 1. Préparation de l'instance AWS
- **Type d'instance**: r6i.xlarge (ou supérieur)
- **OS**: Ubuntu 20.04 LTS
- **Stockage**: 120GB SSD minimum
- **Ports**: Ouvrir le port 22 (SSH) dans le Security Group

### 2. Déploiement automatique
```bash
# Sur votre machine locale
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail

# Déployer sur AWS (remplacez par vos valeurs)
chmod +x deploy_aws.sh
./deploy_aws.sh 3.15.45.67 ~/.ssh/ma-cle.pem 123456:ABC-DEF...
```

### 3. Configuration manuelle
Si vous n'avez pas fourni le token lors du déploiement :
```bash
# Se connecter à l'instance
ssh -i ~/.ssh/ma-cle.pem ubuntu@3.15.45.67

# Aller dans le projet
cd Code-du-Travail

# Configurer le token
nano .env
# Ajouter: TELEGRAM_BOT_TOKEN=votre_token_ici
```

### 4. Démarrage
```bash
# Démarrer le bot en arrière-plan
./start_bot.sh --background

# Vérifier le statut
./status_bot.sh

# Voir les logs
tail -f bot.log
```

## Installation Locale

### 1. Cloner le repository
```bash
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail
```

### 2. Installation automatique
```bash
chmod +x setup.sh
./setup.sh
```

### 3. Configuration
```bash
cp .env.example .env
nano .env
# Ajouter votre TELEGRAM_BOT_TOKEN
```

### 4. Démarrage
```bash
# Activer l'environnement virtuel
source venv/bin/activate

# Option 1: Démarrage direct
python telegram_bot.py

# Option 2: Avec le script de gestion
./start_bot.sh

# Option 3: En arrière-plan
./start_bot.sh --background
```

## 🤖 Création du Bot Telegram

1. **Contactez @BotFather** sur Telegram
2. **Créez un nouveau bot** : `/newbot`
3. **Choisissez un nom** : `Mon Bot Code du Travail`
4. **Choisissez un username** : `mon_code_travail_bot`
5. **Copiez le token** qui ressemble à : `123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`

## 📊 Commandes de Gestion

### Scripts principaux
```bash
./start_bot.sh [--background]    # Démarrer le bot
./stop_bot.sh                    # Arrêter le bot
./status_bot.sh                  # Voir le statut
./update_bot.sh                  # Mettre à jour le code
```

### Monitoring
```bash
python monitor.py                # Vérification unique
python monitor.py --continuous   # Monitoring continu
python health_check.py           # Vérification de santé
```

### Logs et debugging
```bash
tail -f bot.log                  # Voir les logs en temps réel
python run.py --check            # Vérifier la configuration
python run.py --debug            # Mode debug
```

## ⚙️ Configuration Avancée

### Variables d'environnement (.env)
```env
TELEGRAM_BOT_TOKEN=votre_token_ici
MODEL_NAME=Pyzeur/Code-du-Travail-mistral-finetune
DEVICE=auto
MAX_LENGTH=2048
LOG_LEVEL=INFO
```

### Service systemd (production)
```bash
# Le service est automatiquement créé par setup.sh
sudo systemctl start code-du-travail-bot.service
sudo systemctl enable code-du-travail-bot.service
sudo systemctl status code-du-travail-bot.service

# Voir les logs du service
sudo journalctl -u code-du-travail-bot.service -f
```

### Docker (alternative)
```bash
# Build et lancement
docker-compose up -d

# Voir les logs
docker-compose logs -f

# Arrêter
docker-compose down
```

## 🔧 Optimisations GPU

### CUDA et drivers NVIDIA
Le script `setup.sh` installe automatiquement :
- CUDA Toolkit 12.2
- Drivers NVIDIA
- Optimisations mémoire avec quantisation 4-bit

### Vérification GPU
```bash
nvidia-smi                       # État du GPU
python -c "import torch; print(torch.cuda.is_available())"
```

## 🆘 Dépannage

### Problèmes courants

**Bot ne démarre pas :**
```bash
# Vérifier la configuration
python run.py --check

# Vérifier les logs
tail -n 50 bot.log

# Vérifier le token
grep TELEGRAM_BOT_TOKEN .env
```

**Erreur mémoire GPU :**
```bash
# Activer la quantisation
export USE_QUANTIZATION=true
export LOAD_IN_4BIT=true
```

**Modèle ne se charge pas :**
```bash
# Vider le cache HuggingFace
rm -rf ~/.cache/huggingface/

# Vérifier la connexion
ping huggingface.co
```

### Redémarrage d'urgence
```bash
# Tuer tous les processus Python
pkill -f telegram_bot.py

# Redémarrer
./start_bot.sh --background
```

## 📈 Monitoring de Production

### Surveillance automatique
```bash
# Monitoring continu avec alertes
python monitor.py --continuous --interval 30

# Rapport de santé JSON
python health_check.py --json
```

### Intégration avec systemd
```bash
# Activer le redémarrage automatique
sudo systemctl edit code-du-travail-bot.service

# Ajouter :
[Service]
Restart=always
RestartSec=10
```

## 🔄 Mise à jour

### Mise à jour automatique
```bash
./update_bot.sh
```

### Mise à jour manuelle
```bash
# Sauvegarder
cp .env .env.backup

# Mettre à jour
git pull origin main
source venv/bin/activate
pip install -r requirements.txt --upgrade

# Redémarrer
./stop_bot.sh
./start_bot.sh --background
```

## 📞 Support

- **Issues GitHub** : https://github.com/Pyzeur-ColonyLab/Code-du-Travail/issues
- **Logs** : `tail -f bot.log`
- **Configuration** : `python run.py --check`

## ⚡ Commandes Rapides

```bash
# Statut complet en une commande
./status_bot.sh && python monitor.py

# Redémarrage complet
./stop_bot.sh && sleep 2 && ./start_bot.sh --background

# Monitoring avec logs
python monitor.py --continuous & tail -f bot.log
```

---

🎉 **Votre bot est maintenant prêt à répondre aux questions sur le Code du Travail français !**
