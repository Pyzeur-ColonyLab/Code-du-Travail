# Code du Travail - Assistant IA Multi-Plateforme

🤖 Assistant IA intelligent basé sur un modèle Mistral 7B fine-tuné pour répondre aux questions sur le Code du Travail français.

## 🎯 Plateformes Disponibles

- 📱 **Bot Telegram** - Interaction instantanée et conversationnelle
- 📧 **Bot Email** - Réponses détaillées par email avec Gmail

## 🚀 Installation Rapide

### Prérequis
- Python 3.10+
- Instance AWS EC2 (r6i.xlarge recommandée)
- Token bot Telegram + Compte Gmail configuré

### 1. **Clonage et Installation**
```bash
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail
chmod +x setup.sh
./setup.sh
```

### 2. **Configuration**
```bash
cp .env.example .env
vi .env
```

Configurez vos tokens :
```env
# Telegram
TELEGRAM_BOT_TOKEN=votre_token_telegram

# Email Gmail
EMAIL_ADDRESS=votre-bot@gmail.com
EMAIL_PASSWORD=mot_de_passe_application_gmail

# HuggingFace (pour le modèle privé)
HUGGING_FACE_TOKEN=votre_token_hf
```

### 3. **Démarrage**

#### **Bot Telegram**
```bash
./start_bot.sh --background
./status_bot.sh
```

#### **Bot Email**
```bash
./start_email_bot.sh --background
tail -f email_bot.log
```

## 📋 Guides Détaillés

- 📖 **[Guide de Démarrage Rapide](QUICK_START.md)** - Installation et configuration
- 📧 **[Configuration Gmail](EMAIL_SETUP.md)** - Setup complet pour le bot email
- 🛠️ **[Guide Technique](README.md)** - Documentation complète

## 🎮 Utilisation

### **Bot Telegram**
1. Cherchez votre bot sur Telegram
2. Envoyez `/start`
3. Posez vos questions directement

**Commandes disponibles :**
- `/start` - Démarrer
- `/help` - Aide
- `/status` - État du système

### **Bot Email**
1. Envoyez un email à votre bot Gmail
2. Sujet libre
3. Réponse automatique dans 2-5 minutes

**Format des réponses email :**
- Introduction personnalisée
- Réponse détaillée (jusqu'à 1000 tokens)
- Avertissement juridique
- Signature professionnelle

## ⚙️ Caractéristiques Techniques

### **Modèle IA**
- **Base** : Mistral-7B-Instruct-v0.3
- **Fine-tuning** : Adaptateur LoRA spécialisé Code du Travail
- **Optimisations CPU** : Threading + MKL-DNN
- **Performance** : 60-90 secondes par réponse sur CPU

### **Paramètres de Génération**

| Plateforme | max_tokens | temperature | top_p | top_k | Usage |
|------------|------------|-------------|-------|-------|-------|
| **Telegram** | 200 | 0.7 | 0.85 | 25 | Réponses rapides |
| **Email** | 1000 | 0.7 | 0.95 | 75 | Réponses détaillées |

### **Architecture**
- **Déploiement** : AWS EC2 (r6i.xlarge)
- **OS** : Amazon Linux / Ubuntu
- **Stockage** : 120GB SSD
- **RAM** : 30GB (modèle ~15GB + système)

## 📊 Monitoring

### **Scripts de Gestion**
```bash
# Telegram
./start_bot.sh [--background]
./stop_bot.sh
./status_bot.sh

# Email
./start_email_bot.sh [--background]
./stop_email_bot.sh

# Monitoring
python monitor.py [--continuous]
python health_check.py [--json]

# Maintenance
./update_bot.sh
```

### **Logs**
```bash
# Telegram
tail -f bot.log

# Email
tail -f email_bot.log

# Système
./status_bot.sh
```

## 🔧 Optimisations

### **Performance CPU**
- **Threading** : Utilise tous les cœurs CPU
- **MKL-DNN** : Optimisations Intel
- **Inference Mode** : PyTorch optimisé
- **Cache** : KV cache activé

### **Paramètres Optimisés**
- **Réduction tokens** : 200-1000 selon plateforme
- **Sampling efficace** : top_k réduit
- **Pas de quantisation** : Évite ralentissement CPU

## 🚀 Déploiement Production

### **Services Systemd**
```bash
# Installation automatique via setup.sh
sudo systemctl enable code-du-travail-bot.service
sudo systemctl start code-du-travail-bot.service
```

### **Docker (Alternative)**
```bash
docker-compose up -d
docker-compose logs -f
```

### **Monitoring Continu**
```bash
# Surveillance automatique
python monitor.py --continuous --interval 60 &

# Alertes système
python health_check.py --json
```

## 🛡️ Sécurité

### **Configuration Email**
- Compte Gmail dédié
- Authentification 2FA obligatoire
- Mot de passe d'application
- IMAP/SMTP sécurisé

### **Tokens et Accès**
- Variables d'environnement (.env)
- Tokens HuggingFace privés
- Accès modèle restreint

### **Système**
- Firewall AWS configuré
- SSH sécurisé
- Logs centralisés

## 📈 Cas d'Usage

### **Telegram - Usage Interactif**
- ✅ Questions rapides
- ✅ Clarifications immédiates
- ✅ Conversation fluide
- ✅ Références courtes

### **Email - Usage Professionnel**
- ✅ Analyses détaillées
- ✅ Réponses documentées
- ✅ Format professionnel
- ✅ Historique email
- ✅ Consultation approfondie

## 🔄 Maintenance

### **Mise à jour**
```bash
./update_bot.sh
```

### **Sauvegarde**
```bash
# Configuration
cp .env .env.backup

# Logs
tar -czf logs_backup.tar.gz *.log
```

### **Nettoyage**
```bash
# Logs volumineux
truncate -s 0 bot.log email_bot.log

# Cache modèle
rm -rf ~/.cache/huggingface/
```

## 🆘 Dépannage

### **Problèmes Courants**

| Problème | Solution |
|----------|----------|
| Modèle ne charge pas | Vérifier token HuggingFace |
| Bot Telegram muet | Vérifier TELEGRAM_BOT_TOKEN |
| Email ne fonctionne pas | Suivre [EMAIL_SETUP.md](EMAIL_SETUP.md) |
| Mémoire insuffisante | Utiliser instance plus grande |
| Réponses lentes | Optimiser paramètres génération |

### **Logs de Debug**
```bash
# Mode verbose
python run.py --debug

# Vérification complète
python run.py --check

# Santé système
python health_check.py
```

## 🎉 Résultats

### **Performance**
- **Temps de réponse** : 60-90 secondes (CPU optimisé)
- **Qualité** : Spécialisé Code du Travail français
- **Disponibilité** : 24/7 sur AWS
- **Plateformes** : Telegram + Email

### **Utilisateurs**
- **Particuliers** : Questions rapides sur Telegram
- **Professionnels** : Consultations détaillées par email
- **Entreprises** : Intégration dans workflows

## 📞 Support

- **Documentation** : Guides complets dans le repository
- **Issues** : [GitHub Issues](https://github.com/Pyzeur-ColonyLab/Code-du-Travail/issues)
- **Logs** : `tail -f bot.log` pour diagnostic

## ⚠️ Avertissement

Cet assistant fournit des informations à titre informatif uniquement. Pour des conseils juridiques précis concernant le Code du Travail, consultez un avocat spécialisé en droit du travail.

---

**🏗️ Développé par Pyzeur - ColonyLab**  
**🤖 Modèle**: [Code-du-Travail-mistral-finetune](https://huggingface.co/Pyzeur/Code-du-Travail-mistral-finetune)
