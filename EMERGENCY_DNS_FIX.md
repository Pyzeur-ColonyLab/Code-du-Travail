# Emergency DNS Fix - When DNS is Completely Broken

## Immediate Fix Commands

When you get "unable to resolve host" errors, run these commands in order:

### 1. Fix Hostname Resolution First
```bash
# Add localhost to /etc/hosts to fix hostname resolution
echo "127.0.0.1 localhost le-stagiaire" | sudo tee /etc/hosts
```

### 2. Remove DNS Restrictions
```bash
# Try to remove immutable flag (ignore errors)
sudo chattr -i /etc/resolv.conf 2>/dev/null || true
```

### 3. Create Basic DNS Configuration
```bash
# Create a basic working DNS configuration
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
```

### 4. Test Basic Connectivity
```bash
# Test if basic DNS works
nslookup google.com
```

## Alternative Methods (if above doesn't work)

### Method 1: Use IP Addresses Directly
```bash
# Add common services to /etc/hosts
echo "140.82.112.4 github.com" | sudo tee -a /etc/hosts
echo "142.250.185.78 google.com" | sudo tee -a /etc/hosts
```

### Method 2: Restart Network Services
```bash
# Restart network services
sudo systemctl restart systemd-resolved
sudo systemctl restart NetworkManager
```

### Method 3: Use Different DNS Servers
```bash
# Try different DNS servers
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 208.67.222.222
nameserver 208.67.220.220
nameserver 9.9.9.9
EOF
```

## Complete Recovery Process

### Step 1: Fix Hostname
```bash
echo "127.0.0.1 localhost le-stagiaire" | sudo tee /etc/hosts
```

### Step 2: Restore DNS
```bash
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
```

### Step 3: Test
```bash
nslookup github.com
```

### Step 4: Pull Updates
```bash
git pull origin main
```

## If Nothing Works

### Emergency Recovery
```bash
# Check if backup exists
ls -la /etc/resolv.conf*

# If backup exists, restore it
sudo cp /etc/resolv.conf.backup /etc/resolv.conf

# If no backup, create minimal working config
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
```

### Network Reset
```bash
# Reset network configuration
sudo systemctl stop NetworkManager
sudo systemctl stop systemd-resolved
sudo systemctl start systemd-resolved
sudo systemctl start NetworkManager
```

## Prevention

After fixing DNS, avoid making resolv.conf immutable:
```bash
# Don't use chattr +i on resolv.conf
# Instead, use NetworkManager configuration
```

## Quick Commands to Copy/Paste

```bash
# Complete emergency fix (copy/paste all at once)
echo "127.0.0.1 localhost le-stagiaire" | sudo tee /etc/hosts && \
sudo chattr -i /etc/resolv.conf 2>/dev/null || true && \
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF && \
nslookup github.com
``` 