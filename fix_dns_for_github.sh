#!/bin/bash

echo "[INFO] Quick DNS fix to restore GitHub access"
echo "[STEP] Temporarily removing DNS restrictions..."

# Remove immutable flag from resolv.conf
sudo chattr -i /etc/resolv.conf 2>/dev/null || true

# Create a temporary resolv.conf that works for both local and external
sudo tee /etc/resolv.conf > /dev/null <<EOF
# Temporary DNS configuration for GitHub access
# Primary: Cloudflare DNS
nameserver 1.1.1.1
nameserver 1.0.0.1
# Secondary: Google DNS
nameserver 8.8.8.8
nameserver 8.8.4.4
# Local DNS (if available)
nameserver 127.0.0.1
EOF

echo "[STEP] Testing GitHub access..."
if nslookup github.com > /dev/null 2>&1; then
    echo "[SUCCESS] GitHub.com resolves correctly"
else
    echo "[WARNING] GitHub.com still not resolving, trying alternative DNS..."
    # Try alternative DNS servers
    sudo tee /etc/resolv.conf > /dev/null <<EOF
# Alternative DNS configuration
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
fi

echo "[STEP] Testing git pull..."
if git pull origin main; then
    echo "[SUCCESS] Git pull works!"
else
    echo "[ERROR] Git pull still failing"
    echo "[INFO] Try manually: git pull origin main"
fi

echo "[INFO] DNS temporarily fixed for GitHub access"
echo "[INFO] Run ./fix_ubuntu_dns.sh again after git operations if needed" 