#!/bin/bash

# Webserver Startup Script for GCP VM
# This script installs and configures a basic web server

set -e

# Variables
PROJECT_ID="${project_id}"
LOG_FILE="/var/log/startup-script.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

log_message "Starting webserver setup..."

# Update system packages
log_message "Updating system packages..."
apt-get update -y
apt-get upgrade -y

# Install required packages
log_message "Installing required packages..."
apt-get install -y \
    nginx \
    curl \
    wget \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    htop \
    git

# Install Google Cloud Ops Agent for monitoring and logging
log_message "Installing Google Cloud Ops Agent..."
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install
rm add-google-cloud-ops-agent-repo.sh

# Configure Nginx
log_message "Configuring Nginx..."

# Create a custom index.html
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GCP Webserver - Terraform Deployed</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            text-align: center;
            background: rgba(255, 255, 255, 0.1);
            padding: 3rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
            max-width: 600px;
            margin: 2rem;
        }
        h1 {
            font-size: 2.5rem;
            margin-bottom: 1rem;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        p {
            font-size: 1.2rem;
            margin-bottom: 1rem;
            opacity: 0.9;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
            margin: 2rem 0;
            text-align: left;
        }
        .info-item {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            border-radius: 8px;
        }
        .info-label {
            font-weight: bold;
            color: #ffd700;
        }
        .status {
            display: inline-block;
            background: #28a745;
            color: white;
            padding: 0.5rem 1rem;
            border-radius: 20px;
            font-weight: bold;
            margin: 1rem 0;
        }
        .footer {
            margin-top: 2rem;
            opacity: 0.7;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 GCP Webserver</h1>
        <div class="status">✅ Server Online</div>
        <p>Successfully deployed using Terraform on Google Cloud Platform</p>
        
        <div class="info-grid">
            <div class="info-item">
                <div class="info-label">Server Type:</div>
                <div>Nginx Web Server</div>
            </div>
            <div class="info-item">
                <div class="info-label">Platform:</div>
                <div>Google Cloud Platform</div>
            </div>
            <div class="info-item">
                <div class="info-label">Deployment:</div>
                <div>Terraform</div>
            </div>
            <div class="info-item">
                <div class="info-label">Status:</div>
                <div>Running</div>
            </div>
        </div>
        
        <p>This server is protected by GCP firewall rules and configured with proper security groups.</p>
        
        <div class="footer">
            <p>Deployed: <span id="timestamp"></span></p>
            <p>Server IP: <span id="server-ip"></span></p>
        </div>
    </div>

    <script>
        // Set current timestamp
        document.getElementById('timestamp').textContent = new Date().toLocaleString();
        
        // Try to get server IP (this might not work due to security restrictions)
        fetch('/api/ip')
            .then(response => response.text())
            .then(ip => document.getElementById('server-ip').textContent = ip)
            .catch(() => document.getElementById('server-ip').textContent = 'Hidden for security');
    </script>
</body>
</html>
EOF

# Create a health check endpoint
cat > /var/www/html/health << 'EOF'
OK
EOF

# Create a simple API endpoint for IP information
mkdir -p /var/www/html/api
cat > /var/www/html/api/ip << 'EOF'
#!/bin/bash
echo "Content-Type: text/plain"
echo ""
curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/external-ip 2>/dev/null || echo "N/A"
EOF

chmod +x /var/www/html/api/ip

# Configure Nginx with security headers and proper settings
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    location / {
        try_files $uri $uri/ =404;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # API endpoints
    location /api/ {
        access_log off;
        try_files $uri $uri/ =404;
    }

    # Security: deny access to sensitive files
    location ~ /\. {
        deny all;
    }

    location ~ ~$ {
        deny all;
    }
}
EOF

# Configure firewall (ufw)
log_message "Configuring local firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow 80/tcp
ufw allow 443/tcp

# Start and enable services
log_message "Starting services..."
systemctl enable nginx
systemctl start nginx
systemctl enable google-cloud-ops-agent
systemctl start google-cloud-ops-agent

# Create a system user for the application
log_message "Creating application user..."
useradd -r -s /bin/false -d /var/www -c "Web Application User" webuser
chown -R webuser:webuser /var/www/html

# Set up log rotation for application logs
cat > /etc/logrotate.d/webserver << 'EOF'
/var/log/webserver/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 webuser webuser
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}
EOF

# Create log directory
mkdir -p /var/log/webserver
chown webuser:webuser /var/log/webserver

# Configure automatic security updates
log_message "Configuring automatic security updates..."
apt-get install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades

# Create a simple monitoring script
cat > /usr/local/bin/webserver-monitor.sh << 'EOF'
#!/bin/bash

# Simple monitoring script for the webserver
LOG_FILE="/var/log/webserver/monitor.log"

# Function to log with timestamp
log_with_timestamp() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check if nginx is running
if ! systemctl is-active --quiet nginx; then
    log_with_timestamp "ERROR: Nginx is not running. Attempting to restart..."
    systemctl restart nginx
    if systemctl is-active --quiet nginx; then
        log_with_timestamp "INFO: Nginx restarted successfully"
    else
        log_with_timestamp "ERROR: Failed to restart Nginx"
    fi
else
    log_with_timestamp "INFO: Nginx is running normally"
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_with_timestamp "WARNING: Disk usage is at ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | awk 'NR==2{printf "%.2f", $3*100/$2}')
if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    log_with_timestamp "WARNING: Memory usage is at ${MEMORY_USAGE}%"
fi
EOF

chmod +x /usr/local/bin/webserver-monitor.sh

# Set up cron job for monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/webserver-monitor.sh") | crontab -

# Test the web server
log_message "Testing web server..."
sleep 5
if curl -f http://localhost/ > /dev/null 2>&1; then
    log_message "✅ Web server is responding successfully"
else
    log_message "❌ Web server test failed"
fi

if curl -f http://localhost/health > /dev/null 2>&1; then
    log_message "✅ Health check endpoint is working"
else
    log_message "❌ Health check endpoint failed"
fi

# Get instance metadata for logging
INSTANCE_NAME=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/name)
INSTANCE_ZONE=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone | cut -d'/' -f4)
EXTERNAL_IP=$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/external-ip)

log_message "Instance: $INSTANCE_NAME"
log_message "Zone: $INSTANCE_ZONE"
log_message "External IP: $EXTERNAL_IP"
log_message "Project ID: $PROJECT_ID"

# Final status
log_message "🎉 Webserver setup completed successfully!"
log_message "🌐 Server accessible at: http://$EXTERNAL_IP"
log_message "💚 Health check available at: http://$EXTERNAL_IP/health"

# Send success signal to Cloud Logging
logger -t webserver-startup "Webserver setup completed successfully on instance $INSTANCE_NAME"

exit 0