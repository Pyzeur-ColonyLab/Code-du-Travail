# Debian 11 (Bullseye) Setup Guide

This guide provides comprehensive instructions for setting up the Code du Travail AI Assistant on Debian 11 (Bullseye), specifically optimized for Infomaniak Public Cloud instances.

## 🎯 Overview

The Code du Travail AI Assistant is optimized for Debian 11 (Bullseye) with the following features:
- **AI-Powered**: Fine-tuned Mistral 7B model for French labor law
- **Dual Interface**: Telegram bot and email bot
- **Mail Server**: Self-hosted Docker-Mailserver
- **GPU Support**: NVIDIA CUDA acceleration
- **Production Ready**: Optimized for cloud deployment

## 🚀 Quick Setup

### 1. Automated Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail

# Run the comprehensive Debian setup script
chmod +x setup_debian.sh
./setup_debian.sh
```

### 2. Manual Setup

If you prefer manual setup or need to customize the installation:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git build-essential python3 python3-pip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER

# Run optimization scripts
chmod +x debian_optimize.sh
./debian_optimize.sh

# Run DNS fix
chmod +x fix_debian_dns.sh
./fix_debian_dns.sh
```

## 🔧 Configuration

### Environment Setup

Create your `.env` file:

```bash
# Copy example configuration
cp .env.example .env

# Edit with your settings
nano .env
```

Required environment variables:

```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# Hugging Face
HUGGING_FACE_TOKEN=your_hugging_face_token
MODEL_NAME=Pyzeur/Code-du-Travail-mistral-finetune

# Email Configuration
EMAIL_DOMAIN=yourdomain.com
EMAIL_ADDRESS=bot@yourdomain.com
EMAIL_PASSWORD=your_secure_password

# Device Configuration
DEVICE=auto  # auto, cpu, cuda
```

### DNS Configuration

For proper email functionality, configure these DNS records:

```dns
# A record for mail server
mail.yourdomain.com.    IN  A       YOUR_SERVER_IP

# MX record for email routing
yourdomain.com.         IN  MX  10  mail.yourdomain.com.

# SPF record for email authentication
yourdomain.com.         IN  TXT     "v=spf1 mx ~all"
```

## 🏢 Infomaniak Cloud Deployment

### Instance Configuration

Recommended Infomaniak instance specifications:

```bash
# Instance specs
Flavor: a2-ram4-disk50-perf1  # 4GB RAM, 50GB disk
Image: Debian 11.5 bullseye
Security Group: mailserver-sec
```

### Automated Deployment

Use the provided deployment script:

```bash
# Deploy to Infomaniak
chmod +x deploy_infomaniak.sh
./deploy_infomaniak.sh
```

### Manual Deployment

1. **Create Instance**:
   ```bash
   openstack server create \
       --flavor a2-ram4-disk50-perf1 \
       --image "Debian 11.5 bullseye" \
       --security-group mailserver-sec \
       --network ext-net1 \
       --key-name your-key \
       code-du-travail-ai
   ```

2. **Setup Security Group**:
   ```bash
   openstack security group create --description "Mail Server Ports" mailserver-sec
   openstack security group rule create --dst-port 25 --protocol TCP mailserver-sec
   openstack security group rule create --dst-port 587 --protocol TCP mailserver-sec
   openstack security group rule create --dst-port 993 --protocol TCP mailserver-sec
   openstack security group rule create --dst-port 465 --protocol TCP mailserver-sec
   openstack security group rule create --dst-port 22 --protocol TCP mailserver-sec
   ```

3. **Deploy Application**:
   ```bash
   ssh debian@YOUR_INSTANCE_IP
   git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
   cd Code-du-Travail
   ./setup_debian.sh
   ```

## 🎯 Usage

### Start Services

```bash
# Start all services
./start_mailserver_bot.sh start

# Check status
./start_mailserver_bot.sh status

# View logs
./start_mailserver_bot.sh logs
```

### Bot Modes

```bash
# Run both bots (default)
python run.py --mode both

# Run only Telegram bot
python run.py --mode telegram

# Run only email bot
python run.py --mode email

# Debug mode
python run.py --debug
```

### Email Management

```bash
# Create email account
./setup_mailserver.sh create-account user@domain.com password

# Create email alias
./setup_mailserver.sh create-alias support@domain.com user@domain.com

# List accounts
./setup_mailserver.sh list-accounts
```

## 🔧 Troubleshooting

### Common Issues

1. **DNS Resolution Problems**:
   ```bash
   # Run DNS diagnostic
   sudo ./diagnose_debian_dns.sh
   
   # Fix DNS manually
   sudo ./fix_debian_dns.sh
   ```

2. **Docker Build Issues**:
   ```bash
   # Use fallback build
   ./build_with_fallback.sh
   
   # Check Docker logs
   docker-compose logs
   ```

3. **GPU Not Detected**:
   ```bash
   # Check NVIDIA drivers
   nvidia-smi
   
   # Test Docker GPU support
   docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
   ```

4. **Mail Server Issues**:
   ```bash
   # Check mail server logs
   docker-compose logs mailserver
   
   # Test email connectivity
   docker-compose exec telegram-bot python -c "
   import imaplib
   import ssl
   mail = imaplib.IMAP4_SSL('mailserver', 993)
   mail.login('bot@yourdomain.com', 'password')
   print('IMAP connection successful')
   "
   ```

### Performance Optimization

```bash
# Monitor system resources
htop
iotop
nload

# Check GPU usage
nvidia-smi

# Optimize Docker
docker system prune -a
```

## 🔒 Security

### Email Security Features
- **SSL/TLS Encryption**: All email communications encrypted
- **Authentication**: Strong password requirements
- **Anti-spam**: Built-in spam filtering and virus scanning
- **Fail2ban**: Intrusion prevention and rate limiting

### AI Security Features
- **Input Validation**: Sanitized user inputs
- **Rate Limiting**: Prevents abuse and resource exhaustion
- **Error Handling**: Graceful error responses without data leakage
- **Audit Logging**: Comprehensive logging for security monitoring

## 📊 Monitoring

### Log Files

```bash
# Application logs
tail -f logs/mailserver_email_bot.log
tail -f logs/telegram_bot.log

# Docker logs
docker-compose logs -f

# System logs
sudo journalctl -f
```

### Health Checks

```bash
# Service status
docker-compose ps

# Resource usage
docker stats

# System health
free -h
df -h
```

## 🔄 Updates

### System Updates

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker-compose pull

# Restart services
./start_mailserver_bot.sh restart
```

### Application Updates

```bash
# Pull latest code
git pull origin main

# Rebuild containers
docker-compose build --no-cache

# Restart services
./start_mailserver_bot.sh restart
```

## 📞 Support

For issues specific to Debian 11 setup:

1. Check the troubleshooting section above
2. Review the logs for error messages
3. Ensure all prerequisites are met
4. Verify DNS configuration
5. Check Infomaniak instance specifications

## 📝 Notes

- This setup is specifically optimized for Debian 11 (Bullseye)
- The system includes fallback scripts for Ubuntu compatibility
- All scripts include comprehensive error handling
- The setup is designed for production use on Infomaniak Cloud
- GPU acceleration is optional but recommended for optimal performance 