#!/bin/bash
version="0.1.2"
echo "Fixing secrets...(fixsecrets.sh v$version)"
cd /opt/deploy/sp2
old_secrets=$(docker secret ls | awk '{print $1}' | grep -v 'ID' | grep -i sp2prod)
if [ ! -z "$old_secrets" ]; then
    echo "Found old secrets. Removing..."
    docker secret rm $old_secrets
fi
docker secret create sp2prod-dashboard-settings.json ./config/dashboard-settings.json
docker secret create sp2prod-config.json ./config/config.json
docker secret create sp2prod-alert-config.json ./config/alert-config.json
