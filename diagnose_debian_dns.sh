#!/bin/bash

echo "=== Debian 11 DNS Diagnostic and Fix Script ==="
echo "Running on: $(hostname) - $(date)"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

echo "1. Checking current DNS configuration..."
echo "----------------------------------------"
echo "Current /etc/resolv.conf:"
cat /etc/resolv.conf
echo

echo "2. Checking systemd-resolved status..."
echo "-------------------------------------"
systemctl status systemd-resolved --no-pager -l
echo

echo "3. Checking NetworkManager status..."
echo "-----------------------------------"
systemctl status NetworkManager --no-pager -l
echo

echo "4. Checking DNS servers from systemd-resolved..."
echo "------------------------------------------------"
resolvectl dns
echo

echo "5. Checking DNS statistics..."
echo "----------------------------"
resolvectl statistics
echo

echo "6. Testing DNS resolution..."
echo "----------------------------"
echo "Testing with nslookup:"
nslookup google.com
echo

echo "Testing with dig:"
dig google.com +short
echo

echo "7. Checking network interfaces..."
echo "--------------------------------"
ip addr show
echo

echo "8. Checking routing table..."
echo "----------------------------"
ip route show
echo

echo "9. Testing connectivity..."
echo "-------------------------"
ping -c 3 8.8.8.8
echo

echo "10. Checking for DNS conflicts..."
echo "---------------------------------"
netstat -tulpn | grep :53
echo

echo "11. Checking systemd-resolved configuration..."
echo "---------------------------------------------"
cat /etc/systemd/resolved.conf
echo

echo "=== DNS Fix Options ==="
echo "Choose an option:"
echo "1. Fix DNS with Cloudflare (1.1.1.1, 1.0.0.1)"
echo "2. Fix DNS with Google (8.8.8.8, 8.8.4.4)"
echo "3. Fix DNS with Infomaniak DNS"
echo "4. Reset to DHCP DNS"
echo "5. Exit without changes"
echo

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "Fixing DNS with Cloudflare..."
        # Backup current config
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Configure systemd-resolved
        cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=8.8.8.8 8.8.4.4
Domains=~
#LLMNR=yes
#MulticastDNS=yes
#DNSSEC=no
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
EOF
        
        # Restart systemd-resolved
        systemctl restart systemd-resolved
        systemctl enable systemd-resolved
        
        # Create symlink if needed
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        
        echo "DNS fixed with Cloudflare. Testing..."
        sleep 2
        nslookup google.com
        ;;
    2)
        echo "Fixing DNS with Google..."
        # Backup current config
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Configure systemd-resolved
        cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=8.8.8.8 8.8.4.4
FallbackDNS=1.1.1.1 1.0.0.1
Domains=~
#LLMNR=yes
#MulticastDNS=yes
#DNSSEC=no
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
EOF
        
        # Restart systemd-resolved
        systemctl restart systemd-resolved
        systemctl enable systemd-resolved
        
        # Create symlink if needed
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        
        echo "DNS fixed with Google. Testing..."
        sleep 2
        nslookup google.com
        ;;
    3)
        echo "Fixing DNS with Infomaniak DNS..."
        # Backup current config
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Configure systemd-resolved with Infomaniak DNS
        cat > /etc/systemd/resolved.conf << EOF
[Resolve]
DNS=84.234.29.1 84.234.30.1
FallbackDNS=8.8.8.8 1.1.1.1
Domains=~
#LLMNR=yes
#MulticastDNS=yes
#DNSSEC=no
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
EOF
        
        # Restart systemd-resolved
        systemctl restart systemd-resolved
        systemctl enable systemd-resolved
        
        # Create symlink if needed
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        
        echo "DNS fixed with Infomaniak DNS. Testing..."
        sleep 2
        nslookup google.com
        ;;
    4)
        echo "Resetting to DHCP DNS..."
        # Backup current config
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)
        
        # Reset systemd-resolved to default
        cat > /etc/systemd/resolved.conf << EOF
[Resolve]
#DNS=
#FallbackDNS=
#Domains=
#LLMNR=yes
#MulticastDNS=yes
#DNSSEC=no
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
EOF
        
        # Restart systemd-resolved
        systemctl restart systemd-resolved
        systemctl enable systemd-resolved
        
        # Create symlink if needed
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
        
        echo "DNS reset to DHCP. Testing..."
        sleep 2
        nslookup google.com
        ;;
    5)
        echo "Exiting without changes..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
esac

echo
echo "=== Testing DNS Resolution ==="
echo "Testing various domains:"
for domain in google.com github.com debian.org; do
    echo "Testing $domain:"
    nslookup $domain
    echo
done

echo "=== Docker DNS Test ==="
echo "Testing Docker DNS resolution:"
docker run --rm alpine nslookup deb.debian.org

echo
echo "=== Summary ==="
echo "DNS configuration completed!"
echo "Backup saved as: /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)"
echo "To revert changes: cp /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) /etc/resolv.conf" 