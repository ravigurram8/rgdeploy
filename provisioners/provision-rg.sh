#!/bin/bash

sudo mkdir -p "/opt/deploy/sp2"
sudo mkdir -p "/opt/deploy/sp2/logs"
sudo mkdir -p "/opt/deploy/sp2/slogs"
sudo mkdir -p "/opt/deploy/sp2/notification_sink_logs"
sudo mkdir -p "/opt/deploy/sp2/configs"
sudo mkdir -p "/opt/deploy/sp2/integrations"
sudo mkdir -p "/opt/deploy/sp2/topologies"
sudo mkdir -p "/opt/deploy/sp2/catalog"
sudo cp /home/ubuntu/nginx.conf /opt/deploy/sp2
sudo echo -e "RG_HOME='/opt/deploy/sp2'\n" >> /etc/environment
cd /home/ubuntu
sudo tar -czf config.tar.gz config
