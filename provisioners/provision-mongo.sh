#!/bin/bash
sudo wget -qO - https://www.mongodb.org/static/pgp/server-${MONGO_VERSION}.asc | sudo apt-key add -
sudo echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/${MONGO_VERSION} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-${MONGO_VERSION}.list
sudo apt-get update -y
sudo apt-get install -y mongodb-org
sudo apt-get install -y mongodb-org=${MONGO_VERSION}.${MONGO_Full_VERSION} mongodb-org-server=${MONGO_VERSION}.${MONGO_Full_VERSION}  mongodb-org-shell=${MONGO_VERSION}.${MONGO_Full_VERSION}  mongodb-org-mongos=${MONGO_VERSION}.${MONGO_Full_VERSION}  mongodb-org-tools=${MONGO_VERSION}.${MONGO_Full_VERSION}
sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl stop mongod
