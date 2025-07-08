# Manual DNS Fix for GitHub Access

## Quick Fix Commands

If you can't access GitHub after DNS changes, run these commands:

### 1. Remove DNS Restrictions
```bash
sudo chattr -i /etc/resolv.conf
```

### 2. Restore Working DNS
```bash
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF
```

### 3. Test GitHub Access
```bash
nslookup github.com
```

### 4. Try Git Pull
```bash
git pull origin main
```

## Alternative Methods

### Method 1: Use IP Address Directly
```bash
# Add GitHub IP to /etc/hosts temporarily
echo "140.82.112.4 github.com" | sudo tee -a /etc/hosts
```

### Method 2: Use Different DNS Servers
```bash
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 208.67.222.222
nameserver 208.67.220.220
nameserver 8.8.8.8
EOF
```

### Method 3: Restart Network Services
```bash
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager
```

## Permanent Solution

After fixing GitHub access, you can:

1. **Pull the latest changes**
2. **Run the improved DNS configuration**:
   ```bash
   ./fix_ubuntu_dns.sh
   ```

## Troubleshooting

### Check Current DNS
```bash
cat /etc/resolv.conf
```

### Check Network Status
```bash
systemctl status systemd-resolved
systemctl status NetworkManager
```

### Test Different Domains
```bash
nslookup google.com
nslookup cloudflare.com
nslookup github.com
```

## Emergency Recovery

If nothing works, restore from backup:
```bash
sudo cp /etc/resolv.conf.backup /etc/resolv.conf
``` 