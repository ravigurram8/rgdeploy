#!/bin/bash
version="0.1.1"
echo "Fixing swarm....(fixswarm.sh v$version)"
# Remove the stack which is deployed if any
cd /opt/deploy/sp2
echo "Removing sp2 stack"
docker stack remove sp2
echo "Waiting 15 seconds"
sleep 15

# Remove this node from the swarm
echo 'Removing this node from the swarm'
docker swarm leave --force

# Remove the ingress network that is stuck
echo "Removing the stuck ingress network"
docker network ls | grep -e 'ingress.*overlay' | awk '{print $1}'

[ $? -gt 0 ] && echo "Could not remove ingress network. Exiting" && exit 0

echo "Re-initializing the swarm"
docker swarm init

echo "Recreating the secrets"
docker secret create sp2prod-dashboard-settings.json ./config/dashboard-settings.json
docker secret create sp2prod-config.json ./config/config.json
docker secret create sp2prod-alert-config.json ./config/alert-config.json
docker secret ls

echo "You can now re-deploy your stack"
