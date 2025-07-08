#!/bin/bash

echo "[INFO] Configuration for Cloudflare DNS + Infomaniak Network Setup"
echo "[INFO] Domain: cryptomaltese.com"
echo "=============================================="

echo "[STEP] Checking current environment configuration..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "[ERROR] .env file not found!"
    echo "[INFO] Please create .env file with your configuration:"
    echo ""
    echo "TELEGRAM_BOT_TOKEN=your_telegram_token"
    echo "HUGGING_FACE_TOKEN=your_hf_token"
    echo "EMAIL_DOMAIN=cryptomaltese.com"
    echo "EMAIL_ADDRESS=bot@cryptomaltese.com"
    echo "EMAIL_PASSWORD=your_email_password"
    echo ""
    exit 1
fi

# Load environment variables safely
load_env() {
    if [ -f .env ]; then
        while IFS= read -r line; do
            if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
                export "$line"
            fi
        done < .env
    fi
}

load_env

echo "[INFO] Current configuration:"
echo "  Domain: ${EMAIL_DOMAIN:-cryptomaltese.com}"
echo "  Email: ${EMAIL_ADDRESS:-bot@cryptomaltese.com}"
echo "  Mailserver hostname: mail.${EMAIL_DOMAIN:-cryptomaltese.com}"

echo "[STEP] Verifying DNS resolution for your domain..."

# Test domain resolution
if nslookup cryptomaltese.com > /dev/null 2>&1; then
    echo "[SUCCESS] cryptomaltese.com resolves correctly"
else
    echo "[WARNING] cryptomaltese.com DNS resolution failed"
    echo "[INFO] Please check your Cloudflare DNS settings"
fi

# Test mail subdomain
if nslookup mail.cryptomaltese.com > /dev/null 2>&1; then
    echo "[SUCCESS] mail.cryptomaltese.com resolves correctly"
else
    echo "[INFO] mail.cryptomaltese.com not found - this is normal for new setup"
fi

echo "[STEP] Checking Infomaniak network requirements..."

echo "[INFO] For Infomaniak hosting, ensure these DNS records are configured in Cloudflare:"
echo ""
echo "Type    Name                    Value"
echo "A       cryptomaltese.com       [Your Infomaniak IP]"
echo "A       mail.cryptomaltese.com  [Your Infomaniak IP]"
echo "MX      cryptomaltese.com       mail.cryptomaltese.com (priority 10)"
echo "TXT     cryptomaltese.com       v=spf1 a mx ~all"
echo ""

echo "[STEP] Docker network configuration for Infomaniak..."

# Create custom network configuration for Infomaniak
cat > docker-compose.override.yml <<EOF
version: '3.8'
services:
  mailserver:
    environment:
      - PERMIT_DOCKER=network
      - ENABLE_SPF=1
      - ENABLE_DKIM=1
      - ENABLE_DMARC=1
    extra_hosts:
      - "cryptomaltese.com:127.0.0.1"
      - "mail.cryptomaltese.com:127.0.0.1"

networks:
  mail-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
EOF

echo "[SUCCESS] Created docker-compose.override.yml for Infomaniak compatibility"

echo "[STEP] DNS optimization for Cloudflare..."

# Run the DNS fix script
if [ -f fix_debian_dns.sh ]; then
    echo "[INFO] Running Debian DNS optimization for Cloudflare..."
    chmod +x fix_debian_dns.sh
    ./fix_debian_dns.sh
elif [ -f fix_ubuntu_dns.sh ]; then
    echo "[INFO] Running Ubuntu DNS optimization for Cloudflare (fallback)..."
    chmod +x fix_ubuntu_dns.sh
    ./fix_ubuntu_dns.sh
else
    echo "[WARNING] No DNS fix script found"
fi

echo "[INFO] Configuration completed!"
echo ""
echo "[NEXT STEPS]"
echo "1. Ensure your Cloudflare DNS records are configured correctly"
echo "2. Configure your Infomaniak hosting to allow the required ports (25, 143, 587, 993)"
echo "3. Run: ./start_mailserver_bot.sh start"
echo ""
echo "[TROUBLESHOOTING]"
echo "- If DNS issues persist, check Cloudflare DNS settings"
echo "- If port issues occur, contact Infomaniak support"
echo "- For Docker build issues, run: ./build_with_fallback.sh" 