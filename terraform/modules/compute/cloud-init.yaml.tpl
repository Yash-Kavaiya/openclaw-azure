#cloud-config
# OpenClaw VM Bootstrap Script
# Installs Docker, pulls and runs the application container

package_update: true
package_upgrade: true

packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg
  - lsb-release
  - nginx
  - certbot
  - python3-certbot-nginx
  - jq
  - htop
  - fail2ban
  - ufw

write_files:
  - path: /etc/openclaw/environment
    permissions: '0600'
    owner: root:root
    content: |
      ENVIRONMENT=${environment}
      DATABASE_URL=${database_url}
      REDIS_URL=${redis_url}
      AZURE_KEY_VAULT_URL=${key_vault_url}
      APPLICATIONINSIGHTS_CONNECTION_STRING=${app_insights_conn_str}
      PORT=8000
      WORKERS=4

  - path: /etc/systemd/system/openclaw.service
    permissions: '0644'
    content: |
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
      ExecStartPre=/usr/bin/docker pull ${acr_login_server}/openclaw:latest
      ExecStart=/usr/bin/docker run \
        --name openclaw \
        --rm \
        --env-file /etc/openclaw/environment \
        -p 8000:8000 \
        --health-cmd="curl -f http://localhost:8000/api/health || exit 1" \
        --health-interval=30s \
        --health-timeout=10s \
        --health-retries=3 \
        ${acr_login_server}/openclaw:latest
      ExecStop=/usr/bin/docker stop openclaw

      [Install]
      WantedBy=multi-user.target

  - path: /etc/nginx/sites-available/openclaw
    permissions: '0644'
    content: |
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

runcmd:
  # Install Docker
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  - echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  - apt-get update
  - apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  - systemctl enable docker
  - systemctl start docker

  # Login to ACR
  - echo "${acr_admin_password}" | docker login ${acr_login_server} -u ${acr_admin_username} --password-stdin

  # Configure UFW firewall
  - ufw default deny incoming
  - ufw default allow outgoing
  - ufw allow ssh
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw --force enable

  # Configure fail2ban
  - systemctl enable fail2ban
  - systemctl start fail2ban

  # Configure Nginx
  - ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw
  - rm -f /etc/nginx/sites-enabled/default
  - nginx -t && systemctl reload nginx

  # Enable and start OpenClaw service
  - systemctl daemon-reload
  - systemctl enable openclaw
  - systemctl start openclaw

  # Configure log rotation
  - |
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
