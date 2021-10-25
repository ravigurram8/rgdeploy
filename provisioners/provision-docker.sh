#!/bin/bash
sudo apt-get clean
sudo apt-get update -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt-get update
sudo apt-get install -y docker-ce
sudo usermod -aG docker ubuntu
