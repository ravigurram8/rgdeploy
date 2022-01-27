#!/bin/bash
version="0.1.4"
echo "Fixing secrets...(fixsecrets.sh v$version)"

[ -z "$RG_HOME" ] && RG_HOME='/opt/deploy/sp2'
echo "RG_HOME=$RG_HOME"

old_secrets=$(docker secret ls | grep -i sp2prod | awk '{print $1}')
if [ -n "$old_secrets" ]; then
	echo "Found old secrets. Removing..."
	echo "$old_secrets" |
		while IFS=$'\n' read -r mysecret; do
			docker secret rm "$mysecret"
		done
fi
docker secret create sp2prod-config.json "${RG_HOME}/config/config.json"
docker secret create sp2prod-alert-config.json "${RG_HOME}/config/alert-config.json"
