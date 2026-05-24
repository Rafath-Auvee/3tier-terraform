#!/bin/bash
set -e
apt-get update -y
apt-get install -y nginx

cat > /etc/nginx/sites-available/default <<'NGINXEOF'
server {
    listen 80 default_server;
    server_name _;

    location / {
        proxy_pass http://${app_server_ip}:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 10s;
        proxy_read_timeout 30s;
    }
}
NGINXEOF

nginx -t
systemctl start nginx
systemctl enable nginx
