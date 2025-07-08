# 🤖 Code du Travail AI Assistant

[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)
[![Python](https://img.shields.io/badge/Python-3.10+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Intelligent AI Assistant for French Labor Law** - Powered by fine-tuned Mistral 7B model

A comprehensive AI system that provides expert assistance on French labor law through both **Telegram** and **Email** interfaces. Built with a fine-tuned Mistral 7B model specifically trained on the French Code du Travail.

## 🌟 Features

### 🤖 **Dual Interface Support**
- **Telegram Bot**: Interactive chat interface for real-time assistance
- **Email Bot**: Automated email processing with professional responses
- **Simultaneous Operation**: Both bots can run concurrently

### 🧠 **Advanced AI Capabilities**
- **Fine-tuned Model**: Specialized `Pyzeur/Code-du-Travail-mistral-finetune` model
- **LoRA Adapters**: Efficient fine-tuning approach for optimal performance
- **GPU Acceleration**: CUDA support for faster inference
- **Context-Aware**: Different parameters for chat vs. email responses

### 📧 **Professional Email System**
- **Docker-Mailserver**: Self-hosted, production-ready mail server
- **Anti-spam Protection**: Built-in spam filtering and virus scanning
- **SSL/TLS Security**: Encrypted email communications
- **Multiple Domains**: Support for multiple email domains

### 🔧 **Enterprise Features**
- **Docker Containerization**: Easy deployment and scaling
- **Persistent Storage**: Email data and model cache persistence
- **Health Monitoring**: Built-in health checks and logging
- **Security**: Fail2ban, authentication, and input validation

## 🚀 Quick Start

### Prerequisites

- **Debian 11 (Bullseye)** or compatible system
- **Docker & Docker Compose**
- **Domain name** (for email functionality)
- **NVIDIA GPU** (recommended for optimal performance)
- **Basic DNS knowledge**

### 1. Clone Repository
```bash
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail
```

### 2. Setup Environment (Debian 11)

#### Option A: Interactive Setup (Recommended)
```bash
# Download and run the quick setup script
curl -fsSL https://raw.githubusercontent.com/Pyzeur-ColonyLab/Code-du-Travail/main/quick_setup.sh | bash

# Or download and run manually
wget https://raw.githubusercontent.com/Pyzeur-ColonyLab/Code-du-Travail/main/quick_setup.sh
chmod +x quick_setup.sh
./quick_setup.sh
```

#### Option B: Manual Setup
```bash
# Run comprehensive Debian setup
chmod +x setup_debian.sh
./setup_debian.sh
```

#### Option C: Interactive Setup (After cloning)
```bash
# Clone repository first
git clone https://github.com/Pyzeur-ColonyLab/Code-du-Travail.git
cd Code-du-Travail

# Run interactive setup
chmod +x interactive_setup.sh
./interactive_setup.sh
```

### 3. Configure Environment
```bash
cp .env.example .env
# Edit .env with your settings
```

### 4. Start Services
```bash
./start_mailserver_bot.sh start
```

### 5. Setup Email Accounts
```bash
./start_mailserver_bot.sh setup
```

## 📋 Configuration

### Environment Variables

A comprehensive `.env.example` file is provided with all configuration options. Copy it to create your configuration:

```bash
cp .env.example .env
nano .env
```

#### Required Settings
```bash
# Telegram Bot
TELEGRAM_BOT_TOKEN=your_telegram_bot_token

# Email Configuration
EMAIL_DOMAIN=yourdomain.com
EMAIL_ADDRESS=bot@yourdomain.com
EMAIL_PASSWORD=your_secure_password

# AI Model
MODEL_NAME=Pyzeur/Code-du-Travail-mistral-finetune
HUGGING_FACE_TOKEN=your_hugging_face_token
```

#### Optional Settings
```bash
# Device Configuration
DEVICE=auto                    # auto, cpu, cuda

# Email AI Parameters
EMAIL_MAX_TOKENS=1500          # Longer responses for emails
EMAIL_TEMPERATURE=0.3          # More conservative for emails
EMAIL_CHECK_INTERVAL=30        # Check emails every 30 seconds

# Telegram AI Parameters
TELEGRAM_MAX_TOKENS=512        # Shorter responses for chat
TELEGRAM_TEMPERATURE=0.7       # More conversational
```

> **Note**: The `.env.example` file contains detailed documentation for all configuration options, including advanced settings for Cloudflare DNS, OpenStack/Infomaniak integration, Docker configuration, and more.

### DNS Configuration

Configure these DNS records for your domain:

```dns
# A record for mail server
mail.yourdomain.com.    IN  A       YOUR_SERVER_IP

# MX record for email routing
yourdomain.com.         IN  MX  10  mail.yourdomain.com.

# SPF record for email authentication
yourdomain.com.         IN  TXT     "v=spf1 mx ~all"
```

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Telegram Bot  │    │   Email Bot     │    │  Fine-tuned     │
│                 │    │                 │    │  Mistral 7B     │
│ • Interactive   │    │ • IMAP Monitor  │    │ • LoRA Adapters │
│ • Real-time     │    │ • Auto-Reply    │    │ • GPU Support   │
│ • Multi-user    │    │ • Professional  │    │ • Optimized     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Docker-Mailserver│
                    │                 │
                    │ • SMTP/IMAP     │
                    │ • Anti-spam     │
                    │ • SSL/TLS       │
                    │ • Multi-domain  │
                    └─────────────────┘
```

## 🎯 Usage

### Management Commands

```bash
# Start all services
./start_mailserver_bot.sh start

# Check service status
./start_mailserver_bot.sh status

# View logs
./start_mailserver_bot.sh logs

# Stop services
./start_mailserver_bot.sh stop

# Restart services
./start_mailserver_bot.sh restart

# Setup email accounts
./start_mailserver_bot.sh setup
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

## 🏢 Infomaniak Cloud Optimization

This system is optimized for **Infomaniak Public Cloud** instances. Here are the specific optimizations:

### Instance Configuration

```bash
# Recommended Infomaniak instance specs
Flavor: a2-ram4-disk50-perf1  # 4GB RAM, 50GB disk
Image: Debian 11.5 bullseye
Security Group: Open ports 25, 587, 993, 465
```

### Security Group Setup

```bash
# Create security group for mail server
openstack security group create --description "Mail Server Ports" mailserver-sec

# Add required rules
openstack security group rule create --dst-port 25 --protocol TCP mailserver-sec
openstack security group rule create --dst-port 587 --protocol TCP mailserver-sec
openstack security group rule create --dst-port 993 --protocol TCP mailserver-sec
openstack security group rule create --dst-port 465 --protocol TCP mailserver-sec
openstack security group rule create --dst-port 22 --protocol TCP mailserver-sec
```

### Performance Optimization

```bash
# Run Debian optimization script
chmod +x debian_optimize.sh
./debian_optimize.sh

# Or manually:
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Add user to docker group
sudo usermod -aG docker $USER
```

### Resource Management

The system is optimized for Infomaniak's resource constraints:

- **Memory**: Efficient model loading with shared memory between bots
- **Storage**: Optimized Docker layers and persistent volume management
- **Network**: Internal Docker networking for secure communication
- **CPU**: Multi-threading support for concurrent bot operation

## 🔧 Advanced Configuration

### Custom AI Parameters

```bash
# Email responses (detailed and professional)
EMAIL_TEMPERATURE=0.3
EMAIL_TOP_P=0.95
EMAIL_MAX_TOKENS=1500
EMAIL_REPETITION_PENALTY=1.15

# Telegram responses (conversational)
TELEGRAM_TEMPERATURE=0.7
TELEGRAM_TOP_P=0.9
TELEGRAM_MAX_TOKENS=512
TELEGRAM_REPETITION_PENALTY=1.1
```

### Mailserver Customization

```yaml
# Advanced mailserver settings in docker-compose.yml
environment:
  - ENABLE_RSPAMD=1      # Spam filtering
  - ENABLE_CLAMAV=1      # Virus scanning
  - ENABLE_FAIL2BAN=1    # Intrusion prevention
  - SSL_TYPE=self-signed # SSL configuration
  - PERMIT_DOCKER=network # Docker networking
```

## 📊 Monitoring & Logs

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f mailserver
docker-compose logs -f telegram-bot

# Application logs
tail -f logs/mailserver_email_bot.log
tail -f logs/telegram_bot.log
```

### Health Checks

```bash
# Check service status
docker-compose ps

# Check resource usage
docker stats

# Test email connectivity
docker-compose exec telegram-bot python -c "
import imaplib
import ssl
mail = imaplib.IMAP4_SSL('mailserver', 993)
mail.login('bot@yourdomain.com', 'password')
print('IMAP connection successful')
"
```

## 🛠️ Troubleshooting

### Common Issues

1. **Mailserver not starting**
   ```bash
   # Check DNS configuration
   nslookup mail.yourdomain.com
   
   # Check docker logs
   docker-compose logs mailserver
   ```

2. **AI model not loading**
   ```bash
   # Check GPU availability
   docker-compose exec telegram-bot python -c "
   import torch
   print('CUDA available:', torch.cuda.is_available())
   "
   ```

3. **Email bot not connecting**
   ```bash
   # Test IMAP connection
   docker-compose exec telegram-bot python -c "
   import imaplib
   import ssl
   mail = imaplib.IMAP4_SSL('mailserver', 993)
   mail.login('bot@yourdomain.com', 'password')
   print('IMAP connection successful')
   "
   ```

### Performance Issues

```bash
# Check memory usage
free -h

# Check disk space
df -h

# Monitor GPU usage
nvidia-smi

# Optimize Docker
docker system prune -a
```

## 🔒 Security

### Email Security
- **SSL/TLS Encryption**: All email communications encrypted
- **Authentication**: Strong password requirements
- **Anti-spam**: Built-in spam filtering and virus scanning
- **Fail2ban**: Intrusion prevention and rate limiting

### AI Security
- **Input Validation**: Sanitized user inputs
- **Rate Limiting**: Prevents abuse and resource exhaustion
- **Error Handling**: Graceful error responses without data leakage
- **Audit Logging**: Comprehensive logging for security monitoring

## 📈 Performance Optimization

### GPU Optimization

```bash
# Check GPU memory
nvidia-smi

# Optimize CUDA memory allocation
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

### Memory Management

```bash
# Monitor memory usage
docker stats

# Adjust container resources
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 4G
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Mistral AI**: For the base Mistral 7B model
- **Docker-Mailserver**: For the excellent mail server solution
- **Hugging Face**: For model hosting and fine-tuning tools
- **French Labor Law Community**: For domain expertise

## 📞 Support

For support and questions:

1. Check the [DOCKER_MAILSERVER_SETUP.md](DOCKER_MAILSERVER_SETUP.md) for detailed setup instructions
2. Review the troubleshooting section above
3. Check the logs for error messages
4. Open an issue on GitHub

---

**Made with ❤️ for the French labor law community**

*This AI assistant provides informational responses only. For legal advice, please consult a qualified attorney.*
