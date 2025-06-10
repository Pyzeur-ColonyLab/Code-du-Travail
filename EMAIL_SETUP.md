# 📧 Configuration Gmail pour le Bot Email Code du Travail

## 🚀 Guide de Configuration Complet

### **1. Préparer votre compte Gmail**

#### **Option A : Créer un nouveau compte Gmail (recommandé)**
1. Allez sur https://accounts.google.com
2. Créez un nouveau compte dédié au bot (ex: `codedu-travail-bot@gmail.com`)
3. Utilisez un mot de passe fort

#### **Option B : Utiliser un compte existant**
⚠️ **Attention** : Le bot aura accès à tous les emails de ce compte

### **2. Activer l'authentification à 2 facteurs**

1. **Aller dans les paramètres Google** :
   - https://myaccount.google.com/security
   
2. **Activer la vérification en 2 étapes** :
   - Cliquez sur "Vérification en 2 étapes"
   - Suivez les instructions (SMS ou application)

3. **Vérifier l'activation** :
   - Vous devriez voir "Activée" en vert

### **3. Générer un mot de passe d'application**

1. **Retourner dans Sécurité** :
   - https://myaccount.google.com/security

2. **Aller dans "Mots de passe d'application"** :
   - Cliquez sur "Mots de passe d'application"
   - Connectez-vous si demandé

3. **Créer un nouveau mot de passe** :
   - Dans "Sélectionner l'application" : choisir "Autre"
   - Nom : "Code du Travail Bot"
   - Cliquez "Générer"

4. **Copier le mot de passe** :
   - Copiez le mot de passe de 16 caractères
   - **IMPORTANT** : Sauvegardez-le, il ne s'affichera qu'une fois !

### **4. Activer IMAP dans Gmail**

1. **Ouvrir Gmail** : https://gmail.com
2. **Aller dans Paramètres** : ⚙️ → "Voir tous les paramètres"
3. **Onglet "Transfert et POP/IMAP"**
4. **Activer IMAP** :
   - Cochez "Activer IMAP"
   - Cliquez "Enregistrer les modifications"

### **5. Configuration dans le fichier .env**

```bash
# Sur votre instance EC2
cd Code-du-Travail
vi .env
```

**Ajoutez ces lignes à votre fichier .env :**
```env
# Configuration Telegram (existant)
TELEGRAM_BOT_TOKEN=votre_token_telegram
HUGGING_FACE_TOKEN=votre_token_huggingface

# Configuration Email (nouveau)
EMAIL_ADDRESS=votre-email@gmail.com
EMAIL_PASSWORD=abcd efgh ijkl mnop
```

**⚠️ Important :**
- `EMAIL_ADDRESS` : votre adresse Gmail complète
- `EMAIL_PASSWORD` : le mot de passe d'application à 16 caractères (PAS votre mot de passe Gmail normal)

### **6. Exemple de configuration complète**

```env
# Telegram
TELEGRAM_BOT_TOKEN=7801183020:AAEBhlnlGyMe36yJE9SWIuPH96YdsITfFz4
HUGGING_FACE_TOKEN=hf_xxxxxxxxxxxxxxxxxxxxxxxxx

# Email
EMAIL_ADDRESS=codedu-travail-bot@gmail.com
EMAIL_PASSWORD=abcd efgh ijkl mnop

# Modèle
MODEL_NAME=Pyzeur/Code-du-Travail-mistral-finetune
```

## 🧪 Test de Configuration

### **1. Récupérer les fichiers sur votre instance**
```bash
cd Code-du-Travail
git pull origin main
chmod +x start_email_bot.sh
```

### **2. Tester la connexion email**
```bash
source venv/bin/activate
python -c "
import imaplib
import os
from dotenv import load_dotenv

load_dotenv()
email_addr = os.getenv('EMAIL_ADDRESS')
email_pass = os.getenv('EMAIL_PASSWORD')

try:
    mail = imaplib.IMAP4_SSL('imap.gmail.com', 993)
    mail.login(email_addr, email_pass)
    print('✅ Connexion Gmail réussie!')
    mail.logout()
except Exception as e:
    print(f'❌ Erreur: {e}')
"
```

### **3. Démarrer le bot email**
```bash
./start_email_bot.sh --background
```

### **4. Surveiller les logs**
```bash
tail -f email_bot.log
```

## 📱 Test Fonctionnel

### **1. Envoyer un email de test**
- **À** : votre-email@gmail.com
- **Sujet** : Test Code du Travail
- **Corps** : Qu'est-ce qu'un contrat de travail à durée indéterminée ?

### **2. Vérifier la réponse**
Le bot devrait :
1. Détecter l'email dans les 30 secondes
2. Générer une réponse avec votre modèle LoRA
3. Envoyer une réponse formatée avec introduction et footer

## 🔧 Dépannage

### **Erreur "Authentication failed"**
- Vérifiez que l'authentification 2FA est activée
- Régénérez un nouveau mot de passe d'application
- Vérifiez qu'il n'y a pas d'espaces dans le mot de passe

### **Erreur "IMAP not enabled"**
- Retournez dans Gmail → Paramètres → POP/IMAP
- Activez IMAP et sauvegardez

### **Le bot ne répond pas**
```bash
# Vérifier les logs
tail -f email_bot.log

# Vérifier le processus
ps aux | grep email_bot
```

### **Erreur de permissions**
```bash
chmod +x start_email_bot.sh stop_email_bot.sh
```

## 📊 Format des Réponses Email

Le bot génère des emails avec cette structure :

```
Sujet: Re: [Sujet original]

Bonjour,

Merci pour votre question concernant le Code du Travail français. 
Voici ma réponse basée sur ma connaissance du droit du travail :

[RÉPONSE IA DÉTAILLÉE - jusqu'à 1000 tokens]

---
⚠️ Cette réponse est fournie à titre informatif uniquement. 
Pour des conseils juridiques précis et personnalisés, 
je vous recommande de consulter un avocat spécialisé en droit du travail.

Cordialement,
Assistant IA Code du Travail
```

## 🚀 Démarrage en Production

Une fois testé, vous pouvez avoir **les deux bots en parallèle** :

```bash
# Bot Telegram
./start_bot.sh --background

# Bot Email  
./start_email_bot.sh --background

# Vérifier les deux
./status_bot.sh
ps aux | grep email_bot
```

## 📝 Conseils d'Usage

### **Sécurité**
- Utilisez un compte Gmail dédié
- Ne partagez jamais le mot de passe d'application
- Surveillez régulièrement l'activité du compte

### **Performance**
- Le bot email utilise des paramètres optimisés pour des réponses plus longues
- Temps de réponse : 2-5 minutes par email selon la complexité

### **Maintenance**
- Vérifiez les logs régulièrement
- Le bot marque automatiquement les emails comme lus après traitement
- Sauvegardez votre configuration .env

---

🎉 **Votre bot email Code du Travail est maintenant prêt !**

Les utilisateurs peuvent maintenant envoyer leurs questions par email et recevoir des réponses détaillées générées par votre modèle fine-tuné.
