# Docker-Mailserver Integration Setup Guide

This guide explains how to set up and use the Code du Travail AI Bots with Docker-Mailserver instead of ProtonMail.

## Overview

The system now includes:
- **Docker-Mailserver**: A full-featured, production-ready mail server
- **Telegram Bot**: Interactive AI assistant for Telegram
- **Email Bot**: AI assistant that processes emails automatically
- **Unified Orchestration**: Both bots can run simultaneously

## Prerequisites

- Docker and Docker Compose installed
- A domain name (for email functionality)
- Basic knowledge of DNS configuration
- NVIDIA GPU (recommended for faster AI inference)

## Quick Start

1. **Clone and Setup**
   ```bash
   git clone <repository-url>
   cd Code-du-Travail
   cp .env.example .env
   ```

2. **Configure Environment**
   Edit `.env` with your settings:
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

3. **Start Services**
   ```bash
   ./start_mailserver_bot.sh start
   ```

4. **Setup Email Accounts**
   ```bash
   ./start_mailserver_bot.sh setup
   ```

## Configuration

### Environment Variables

#### Required Variables
- `TELEGRAM_BOT_TOKEN`: Your Telegram bot token
- `EMAIL_DOMAIN`: Your domain (e.g., `example.com`)
- `EMAIL_ADDRESS`: Main bot email address
- `EMAIL_PASSWORD`: Password for email accounts
- `MODEL_NAME`: HuggingFace model name
- `HUGGING_FACE_TOKEN`: Your HuggingFace token

#### Optional Variables
- `DEVICE`: CPU/GPU device (`auto`, `cpu`, `cuda`)
- `EMAIL_MAX_TOKENS`: Max tokens for email responses (1500)
- `EMAIL_TEMPERATURE`: AI temperature for emails (0.3)
- `EMAIL_CHECK_INTERVAL`: Email check interval in seconds (30)

### DNS Configuration

For your domain to work with the mailserver, configure these DNS records:

```
# A record for the mail server
mail.yourdomain.com.    IN  A       YOUR_SERVER_IP

# MX record for email routing
yourdomain.com.         IN  MX  10  mail.yourdomain.com.

# Optional: SPF record for email authentication
yourdomain.com.         IN  TXT     "v=spf1 mx ~all"
```

## Usage

### Starting the System

```bash
# Start all services
./start_mailserver_bot.sh start

# Check status
./start_mailserver_bot.sh status

# View logs
./start_mailserver_bot.sh logs

# Stop services
./start_mailserver_bot.sh stop
```

### Email Account Management

```bash
# Setup initial accounts and aliases
./start_mailserver_bot.sh setup

# Create additional accounts
./setup_mailserver.sh create-account newuser@yourdomain.com password123

# Create aliases
./setup_mailserver.sh create-alias support@yourdomain.com bot@yourdomain.com

# List accounts
./setup_mailserver.sh list-accounts
```

### Bot Modes

The system supports three operational modes:

1. **Both Bots (Default)**
   ```bash
   python run.py --mode both
   ```

2. **Telegram Only**
   ```bash
   python run.py --mode telegram
   ```

3. **Email Only**
   ```bash
   python run.py --mode email
   ```

## Architecture

### Components

1. **Docker-Mailserver Container**
   - Full-featured mail server with IMAP/SMTP
   - Anti-spam and anti-virus protection
   - Self-signed SSL certificates
   - Persistent storage for emails

2. **AI Bots Container**
   - Telegram bot for interactive chat
   - Email bot for automated responses
   - Shared fine-tuned Mistral model
   - GPU acceleration support

3. **Shared Network**
   - Internal Docker network for communication
   - Secure inter-container communication

### Data Persistence

```
docker-data/
├── dms/
│   ├── config/          # Mailserver configuration
│   ├── mail-data/       # Email storage
│   ├── mail-state/      # Server state
│   └── mail-logs/       # Mail logs
├── logs/               # Application logs
└── cache/              # Model cache
```

## Features

### Email Bot Features

- **Automatic Email Processing**: Monitors IMAP for new emails
- **AI-Powered Responses**: Uses fine-tuned Mistral model
- **Smart Filtering**: Skips auto-replies and system messages
- **Detailed Responses**: Optimized for comprehensive legal advice
- **Professional Formatting**: Proper email structure with disclaimers

### Telegram Bot Features

- **Interactive Chat**: Real-time conversation with AI
- **Quick Responses**: Optimized for chat-style interaction
- **Multi-user Support**: Handles multiple concurrent users
- **Rich Formatting**: Markdown support for better readability

### Shared AI Model

- **Fine-tuned Mistral 7B**: Specialized for French labor law
- **LoRA Adapters**: Efficient fine-tuning approach
- **GPU Acceleration**: CUDA support for faster inference
- **Optimized Parameters**: Different settings for email vs. chat

## Troubleshooting

### Common Issues

1. **Mailserver not starting**
   ```bash
   # Check docker logs
   docker-compose logs mailserver
   
   # Verify DNS configuration
   nslookup mail.yourdomain.com
   ```

2. **Email bot not connecting**
   ```bash
   # Check IMAP/SMTP settings
   docker-compose exec telegram-bot python -c "
   import imaplib
   import ssl
   mail = imaplib.IMAP4_SSL('mailserver', 993)
   mail.login('bot@yourdomain.com', 'password')
   print('IMAP connection successful')
   "
   ```

3. **AI model not loading**
   ```bash
   # Check GPU availability
   docker-compose exec telegram-bot python -c "
   import torch
   print('CUDA available:', torch.cuda.is_available())
   "
   ```

### Logs and Monitoring

```bash
# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f mailserver
docker-compose logs -f telegram-bot

# View AI bot logs
tail -f logs/mailserver_email_bot.log
tail -f logs/telegram_bot.log
```

## Security Considerations

### Email Security

- **SSL/TLS**: All connections use encryption
- **Authentication**: Strong password requirements
- **Spam Protection**: Built-in anti-spam measures
- **Virus Scanning**: ClamAV integration

### AI Security

- **Input Validation**: Sanitized user inputs
- **Rate Limiting**: Prevents abuse
- **Error Handling**: Graceful error responses
- **Logging**: Comprehensive audit trail

## Advanced Configuration

### Custom AI Parameters

Edit `.env` to customize AI behavior:

```bash
# Email AI Settings (more conservative)
EMAIL_TEMPERATURE=0.3
EMAIL_TOP_P=0.95
EMAIL_MAX_TOKENS=1500
EMAIL_REPETITION_PENALTY=1.15

# Telegram AI Settings (more conversational)
TELEGRAM_TEMPERATURE=0.7
TELEGRAM_TOP_P=0.9
TELEGRAM_MAX_TOKENS=512
```

### Mailserver Customization

Advanced mailserver settings in `docker-compose.yml`:

```yaml
environment:
  - ENABLE_RSPAMD=1      # Spam filtering
  - ENABLE_CLAMAV=1      # Virus scanning
  - ENABLE_FAIL2BAN=1    # Intrusion prevention
  - SSL_TYPE=self-signed # SSL configuration
  - PERMIT_DOCKER=network # Docker networking
```

## Performance Optimization

### GPU Optimization

```bash
# Check GPU memory usage
nvidia-smi

# Optimize for multiple models
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
```

### Memory Management

```bash
# Monitor memory usage
docker stats

# Adjust container resources in docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 4G
```

## Support

For issues and questions:

1. Check the logs for error messages
2. Verify DNS and networking configuration
3. Ensure all environment variables are set correctly
4. Review the Docker-Mailserver documentation
5. Test AI model loading independently

## Migration from ProtonMail

If migrating from the previous ProtonMail setup:

1. **Backup Configuration**: Save your existing `.env` file
2. **Update Settings**: Copy relevant settings to new format
3. **Test Thoroughly**: Verify both email and Telegram functionality
4. **Clean Up**: Remove old ProtonMail-specific files

The new system provides better integration, more control, and enhanced features while maintaining compatibility with your existing AI model. 