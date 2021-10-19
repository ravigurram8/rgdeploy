#!/bin/bash
version="0.1.0"
cd /opt/deploy/sp2
docker secret rm $(docker secret ls | awk '{print $1}' | grep -v 'ID')
docker secret create sp2prod-dashboard-settings.json ./config/dashboard-settings.json
docker secret create sp2prod-config.json ./config/config.json
docker secret create sp2prod-alert-config.json ./config/alert-config.json
