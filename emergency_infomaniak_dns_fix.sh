#!/bin/bash

echo "=== Emergency Infomaniak DNS Fix ==="
echo "This script will quickly fix DNS issues on Infomaniak servers"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "1. Backing up current DNS configuration..."
cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)

echo "2. Stopping systemd-resolved..."
systemctl stop systemd-resolved

echo "3. Creating manual resolv.conf with working DNS servers..."
cat > /etc/resolv.conf << 'EOF'
# Emergency DNS fix for Infomaniak
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

echo "4. Testing DNS resolution..."
echo "Testing with nslookup:"
if nslookup google.com > /dev/null 2>&1; then
    echo "✓ DNS resolution working!"
    nslookup google.com | grep -E "(Name:|Address:)"
else
    echo "✗ DNS resolution still failing"
fi

echo
echo "5. Testing GitHub connectivity..."
if nslookup github.com > /dev/null 2>&1; then
    echo "✓ GitHub DNS resolution working!"
else
    echo "✗ GitHub DNS resolution failing"
fi

echo
echo "6. Testing Docker Hub connectivity..."
if nslookup registry-1.docker.io > /dev/null 2>&1; then
    echo "✓ Docker Hub DNS resolution working!"
else
    echo "✗ Docker Hub DNS resolution failing"
fi

echo
echo "=== Quick Test Commands ==="
echo "Test DNS: nslookup google.com"
echo "Test GitHub: nslookup github.com"
echo "Test Docker: nslookup registry-1.docker.io"
echo "Test ping: ping -c 3 8.8.8.8"
echo
echo "If DNS is working, you can now:"
echo "- Pull Docker images: docker pull ubuntu:22.04"
echo "- Clone from GitHub: git clone https://github.com/your-repo"
echo "- Update packages: apt update"
echo
echo "To restore original DNS later:"
echo "sudo cp /etc/resolv.conf.backup.* /etc/resolv.conf"
echo "sudo systemctl start systemd-resolved" 