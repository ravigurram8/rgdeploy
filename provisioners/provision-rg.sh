#!/bin/bash

mkdir -p "/opt/deploy/sp2"
mkdir -p "/opt/deploy/sp2/logs"
mkdir -p "/opt/deploy/sp2/slogs"
mkdir -p "/opt/deploy/sp2/notification_sink_logs"
mkdir -p "/opt/deploy/sp2/configs"
mkdir -p "/opt/deploy/sp2/integrations"
mkdir -p "/opt/deploy/sp2/topologies"
mkdir -p "/opt/deploy/sp2/catalog"

echo -e "RG_HOME='/opt/deploy/sp2'\n" >> /etc/environment
