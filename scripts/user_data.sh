#!/bin/bash
set -euxo pipefail

# Update package metadata and install Nginx
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# Start Nginx now and enable it after reboot
systemctl enable nginx
systemctl start nginx

# Publish a simple project landing page
cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AWS Multi-AZ Web Infrastructure</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      background: #f3f6fb;
      color: #172033;
    }
    main {
      max-width: 760px;
      margin: 24px;
      padding: 36px;
      background: white;
      border-radius: 14px;
      box-shadow: 0 8px 28px rgba(20, 35, 70, 0.12);
    }
    h1 { color: #1455a3; }
    code { background: #eef2f7; padding: 3px 6px; border-radius: 4px; }
  </style>
</head>
<body>
  <main>
    <h1>Highly Available &amp; Resilient Multi-AZ Web Infrastructure on AWS</h1>
    <p>This web server is running on an EC2 instance using Nginx.</p>
    <p>Traffic is intended to reach the application through the AWS Application Load Balancer.</p>
    <p><strong>Platform:</strong> AWS EC2 | Ubuntu Linux | Nginx</p>
  </main>
</body>
</html>
HTML

# Validate the Nginx configuration and reload the service
nginx -t
systemctl reload nginx
