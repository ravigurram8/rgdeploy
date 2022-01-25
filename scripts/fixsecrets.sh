#!/bin/bash
version="0.1.3"
echo "Fixing secrets...(fixsecrets.sh v$version)"

[ -z "$RG_HOME" ] && RG_HOME='/opt/deploy/sp2'
echo "RG_HOME=$RG_HOME"

cd "$RG_HOME" || echo "Could not cd to $RG_HOME" && exit 1
old_secrets=$(docker secret ls | grep -i sp2prod | awk '{print $1}')
if [ ! -z "$old_secrets" ]; then
	echo "Found old secrets. Removing..."
	docker secret rm "$old_secrets"
fi
docker secret create sp2prod-config.json ./config/config.json
docker secret create sp2prod-alert-config.json ./config/alert-config.json
