#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get install -y nginx

cat >/var/www/html/index.html <<'HTML'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>VCC Assignment - MIG Instance</title>
  </head>
  <body>
    <h1>VCC Assignment</h1>
    <p>This page is served from an autoscaled VM instance.</p>
  </body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
