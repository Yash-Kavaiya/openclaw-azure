#!/usr/bin/env bash
# ============================================================
# OpenClaw VM Setup Script
# Manually provision a VM if not using cloud-init
# Run as root on a fresh Ubuntu 24.04 VM
# ============================================================
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "=================================================="
echo "  OpenClaw VM Setup"
echo "=================================================="

# ---- System Updates ----
apt-get update && apt-get upgrade -y
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  nginx \
  certbot \
  python3-certbot-nginx \
  jq \
  htop \
  fail2ban \
  ufw \
  unzip

# ---- Docker ----
if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable docker
  systemctl start docker
  usermod -aG docker azureuser
  echo "✓ Docker installed"
fi

# ---- Azure CLI ----
if ! command -v az &>/dev/null; then
  echo "Installing Azure CLI..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash
  echo "✓ Azure CLI installed"
fi

# ---- App directories ----
mkdir -p /etc/openclaw /var/log/openclaw /opt/openclaw

# ---- Firewall ----
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
echo "✓ UFW firewall configured"

# ---- Fail2ban ----
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
EOF

systemctl enable fail2ban
systemctl restart fail2ban
echo "✓ Fail2ban configured"

# ---- Nginx ----
cat > /etc/nginx/sites-available/openclaw << 'NGINX'
upstream openclaw_backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

server {
    listen 80;
    server_name _;

    location /api/health {
        proxy_pass http://openclaw_backend;
        access_log off;
    }

    location / {
        proxy_pass http://openclaw_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        client_max_body_size 50M;
        proxy_connect_timeout 60s;
        proxy_read_timeout 60s;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
echo "✓ Nginx configured"

# ---- Log rotation ----
cat > /etc/logrotate.d/openclaw << 'EOF'
/var/log/openclaw/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
}
EOF

# ---- Systemd service ----
cat > /etc/systemd/system/openclaw.service << 'EOF'
[Unit]
Description=OpenClaw Application
After=docker.service network-online.target
Requires=docker.service
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=10
EnvironmentFile=/etc/openclaw/environment
ExecStartPre=-/usr/bin/docker stop openclaw
ExecStartPre=-/usr/bin/docker rm openclaw
ExecStart=/usr/bin/docker run \
    --name openclaw \
    --rm \
    --env-file /etc/openclaw/environment \
    -p 8000:8000 \
    --health-cmd="curl -f http://localhost:8000/api/health || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    ${ACR_LOGIN_SERVER}/openclaw:latest
ExecStop=/usr/bin/docker stop openclaw

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
echo "✓ Systemd service configured"

echo ""
echo "=================================================="
echo "  VM setup complete!"
echo ""
echo "  Next steps:"
echo "  1. Create /etc/openclaw/environment with your settings"
echo "  2. Run: systemctl enable --now openclaw"
echo "  3. For SSL: certbot --nginx -d your-domain.com"
echo "=================================================="
