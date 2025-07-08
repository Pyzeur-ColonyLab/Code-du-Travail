# Cloudflare DNS Configuration for Code du Travail Mailserver

## Overview
This guide helps you configure Cloudflare DNS for your `cryptomaltese.com` domain to work with the Docker mailserver setup.

## Required DNS Records

### 1. A Records
Configure these A records in your Cloudflare dashboard:

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | `cryptomaltese.com` | `[Your Infomaniak IP]` | DNS only |
| A | `mail.cryptomaltese.com` | `[Your Infomaniak IP]` | DNS only |

### 2. MX Record
| Type | Name | Content | Priority |
|------|------|---------|----------|
| MX | `cryptomaltese.com` | `mail.cryptomaltese.com` | 10 |

### 3. TXT Records
| Type | Name | Content |
|------|------|---------|
| TXT | `cryptomaltese.com` | `v=spf1 a mx ~all` |
| TXT | `cryptomaltese.com` | `v=dmarc1; p=quarantine; rua=mailto:dmarc@cryptomaltese.com` |

## Important Notes

### Proxy Status
- **DNS only** (gray cloud): Use this for mail-related records
- **Proxied** (orange cloud): Avoid for mail records as it can interfere with email delivery

### Port Configuration
Ensure your Infomaniak hosting allows these ports:
- **25** (SMTP)
- **143** (IMAP)
- **587** (SMTP submission)
- **993** (IMAP SSL)

## Step-by-Step Configuration

### 1. Access Cloudflare Dashboard
1. Log in to your Cloudflare account
2. Select `cryptomaltese.com`
3. Go to **DNS** → **Records**

### 2. Add A Records
1. Click **Add record**
2. Type: `A`
3. Name: `cryptomaltese.com` (or leave blank for root domain)
4. IPv4 address: `[Your Infomaniak IP]`
5. Proxy status: **DNS only** (gray cloud)
6. Click **Save**

Repeat for `mail.cryptomaltese.com`

### 3. Add MX Record
1. Click **Add record**
2. Type: `MX`
3. Name: `cryptomaltese.com` (or leave blank for root domain)
4. Mail server: `mail.cryptomaltese.com`
5. Priority: `10`
6. Proxy status: **DNS only** (gray cloud)
7. Click **Save**

### 4. Add TXT Records
1. Click **Add record**
2. Type: `TXT`
3. Name: `cryptomaltese.com` (or leave blank for root domain)
4. Content: `v=spf1 a mx ~all`
5. Click **Save**

Repeat for DMARC record with content: `v=dmarc1; p=quarantine; rua=mailto:dmarc@cryptomaltese.com`

## Verification

### Test DNS Resolution
```bash
# Test A record
nslookup cryptomaltese.com
nslookup mail.cryptomaltese.com

# Test MX record
nslookup -type=mx cryptomaltese.com

# Test TXT records
nslookup -type=txt cryptomaltese.com
```

### Test from Docker Container
```bash
docker run --rm alpine nslookup cryptomaltese.com
docker run --rm alpine nslookup mail.cryptomaltese.com
```

## Troubleshooting

### Common Issues

1. **DNS Propagation**
   - DNS changes can take up to 24 hours to propagate globally
   - Use `dig` or `nslookup` to check propagation

2. **Proxy Interference**
   - Ensure mail records are set to **DNS only**
   - Proxied records can block email traffic

3. **Port Blocking**
   - Contact Infomaniak support to ensure ports 25, 143, 587, 993 are open
   - Some hosting providers block port 25 by default

### Verification Commands
```bash
# Check if ports are accessible
telnet cryptomaltese.com 25
telnet cryptomaltese.com 587
telnet cryptomaltese.com 993

# Check DNS propagation
dig cryptomaltese.com
dig mail.cryptomaltese.com
```

## Security Considerations

1. **SPF Record**: Helps prevent email spoofing
2. **DMARC Record**: Provides reporting on email authentication
3. **DKIM**: Will be automatically configured by the mailserver

## Next Steps

After configuring DNS:
1. Run the configuration script: `./configure_cloudflare_infomaniak.sh`
2. Start the mailserver: `./start_mailserver_bot.sh start`
3. Test email functionality

## Support

If you encounter issues:
1. Check Cloudflare DNS settings
2. Verify Infomaniak port configuration
3. Review mailserver logs: `docker logs mailserver` 