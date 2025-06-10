# Code du Travail - Telegram Bot

🤖 Un bot Telegram intelligent basé sur un modèle Mistral 7B fine-tuné pour répondre aux questions sur le Code du Travail français.

## 🎯 Fonctionnalités

- **IA Spécialisée**: Modèle Mistral 7B fine-tuné spécifiquement pour le droit du travail français
- **Interface Telegram**: Interaction simple et intuitive via Telegram
- **Optimisé GPU**: Support CUDA avec quantisation 4-bit pour optimiser l'utilisation mémoire
- **Déploiement AWS**: Configuration prête pour instance EC2
- **Monitoring**: Logs détaillés et informations système

## 🚀 Installation Rapide

### Prérequis

- Python 3.10+
- CUDA 12.2+ (pour GPU)
- Token de bot Telegram
- Instance AWS r6i.xlarge (recommandée)

### 1. Cloner le repository

```bash
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail
```

### 2. Installation automatique (recommandée)

```bash
chmod +x setup.sh
./setup.sh
```

### 3. Configuration

```bash
# Copier le fichier d'exemple
cp .env.example .env

# Éditer et ajouter votre token Telegram
nano .env
```

Ajoutez votre token dans le fichier `.env`:
```env
TELEGRAM_BOT_TOKEN=votre_token_ici
```

### 4. Lancement

#### Option A: Lancement direct
```bash
source venv/bin/activate
python telegram_bot.py
```

#### Option B: Avec le script de lancement
```bash
source venv/bin/activate
python run.py
```

#### Option C: Service systemd
```bash
sudo systemctl start code-du-travail-bot.service
sudo systemctl enable code-du-travail-bot.service
```

#### Option D: Docker
```bash
docker-compose up -d
```

## 📋 Configuration Détaillée

### Variables d'environnement

| Variable | Description | Défaut |
|----------|-------------|--------|
| `TELEGRAM_BOT_TOKEN` | Token du bot Telegram | **Requis** |
| `MODEL_NAME` | Nom du modèle HuggingFace | `Pyzeur/Code-du-Travail-mistral-finetune` |
| `DEVICE` | Périphérique (auto/cuda/cpu) | `auto` |
| `MAX_LENGTH` | Longueur maximale du contexte | `2048` |
| `LOG_LEVEL` | Niveau de logging | `INFO` |

### Paramètres de génération

Le modèle utilise les paramètres suivants pour la génération:
- **Temperature**: 0.7 (créativité modérée)
- **Top-p**: 0.9 (nucleus sampling)
- **Top-k**: 50 (limitation du vocabulaire)
- **Max tokens**: 512 (longueur de réponse)

## 🔧 Installation Manuelle

### 1. Dépendances système

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y python3 python3-pip python3-venv git wget curl build-essential

# Installation CUDA (pour GPU)
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-keyring_1.0-1_all.deb
sudo dpkg -i cuda-keyring_1.0-1_all.deb
sudo apt-get update
sudo apt-get -y install cuda-toolkit-12-2
```

### 2. Environnement Python

```bash
# Créer un environnement virtuel
python3 -m venv venv
source venv/bin/activate

# Installer les dépendances
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Configuration du bot Telegram

1. **Créer un bot Telegram**:
   - Contactez [@BotFather](https://t.me/botfather) sur Telegram
   - Utilisez `/newbot` pour créer un nouveau bot
   - Suivez les instructions et notez le token

2. **Configurer le bot**:
   ```bash
   cp .env.example .env
   # Éditer .env et ajouter votre token
   ```

## 🐳 Déploiement Docker

### Build et lancement

```bash
# Build l'image
docker build -t code-du-travail-bot .

# Lancement avec Docker Compose
docker-compose up -d

# Vérifier les logs
docker-compose logs -f
```

### Configuration GPU pour Docker

Assurez-vous d'avoir installé `nvidia-docker2`:

```bash
# Installation nvidia-docker2
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

## 📊 Monitoring et Maintenance

### Vérifier le statut

```bash
# Statut du service
sudo systemctl status code-du-travail-bot.service

# Logs en temps réel
tail -f bot.log

# Logs du service systemd
sudo journalctl -u code-du-travail-bot.service -f
```

### Commandes du bot

| Commande | Description |
|----------|-------------|
| `/start` | Démarrer et afficher l'aide |
| `/help` | Afficher l'aide détaillée |
| `/status` | Informations système et état du modèle |

### Surveillance des ressources

Le bot inclut un monitoring intégré accessible via `/status`:
- Utilisation CPU et RAM
- Espace disque
- État du GPU (si disponible)
- Statut du modèle

## 🔍 Dépannage

### Problèmes courants

1. **Erreur "CUDA out of memory"**:
   ```bash
   # Réduire la taille du batch ou utiliser la quantisation
   export USE_QUANTIZATION=true
   export LOAD_IN_4BIT=true
   ```

2. **Token Telegram invalide**:
   - Vérifiez le token dans `.env`
   - Assurez-vous qu'il n'y a pas d'espaces

3. **Modèle ne se charge pas**:
   ```bash
   # Vérifier la connexion internet
   ping huggingface.co
   
   # Vider le cache
   rm -rf ~/.cache/huggingface/
   ```

4. **Permissions insuffisantes**:
   ```bash
   # Donner les bonnes permissions
   chmod +x setup.sh
   chmod +x run.py
   ```

### Logs et débogage

```bash
# Augmenter le niveau de logging
export LOG_LEVEL=DEBUG

# Lancer en mode debug
python run.py --debug

# Vérifier les dépendances
python run.py --check
```

## 🏗️ Architecture du Projet

```
Code-du-Travail/
├── telegram_bot.py      # Bot principal
├── config.py           # Configuration
├── run.py              # Script de lancement
├── requirements.txt    # Dépendances Python
├── setup.sh           # Script d'installation
├── Dockerfile         # Configuration Docker
├── docker-compose.yml # Orchestration Docker
├── .env.example       # Exemple de configuration
└── README.md          # Documentation
```

## 🔒 Sécurité

- **Variables d'environnement**: Utilisez `.env` pour les tokens sensibles
- **Firewall**: Limitez les accès réseau sur votre instance AWS
- **Mises à jour**: Maintenez les dépendances à jour
- **Monitoring**: Surveillez les logs pour détecter les anomalies

## 📈 Performance

### Optimisations GPU

- **Quantisation 4-bit**: Réduit l'utilisation mémoire de ~75%
- **Device mapping automatique**: Optimise la répartition sur GPU
- **Batch processing**: Traitement efficace des requêtes

### Instance AWS recommandée

- **Type**: r6i.xlarge ou supérieur
- **RAM**: 32GB minimum
- **Storage**: 120GB SSD
- **GPU**: Optionnel mais recommandé (g4dn.xlarge)

## 🤝 Contribution

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Committez vos changements (`git commit -am 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrez une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 🆘 Support

- **Issues GitHub**: [Créer un ticket](https://github.com/Pyzeur-ColonyLab/Code-du-Travail/issues)
- **Documentation**: Ce README contient toutes les informations nécessaires
- **Logs**: Consultez `bot.log` pour le débogage

## ⚠️ Avertissement

Ce bot fournit des informations à titre informatif uniquement. Pour des conseils juridiques précis concernant le Code du Travail, consultez un avocat spécialisé en droit du travail.

---

**Modèle**: [Pyzeur/Code-du-Travail-mistral-finetune](https://huggingface.co/Pyzeur/Code-du-Travail-mistral-finetune)  
**Développé par**: Pyzeur - ColonyLab