#!/bin/bash -xe
sudo apt-get update -y
sudo apt -y install python3-pip
sudo mkdir -p /opt/aws/bin
sudo wget https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
sudo python3 -m easy_install --script-dir /opt/aws/bin aws-cfn-bootstrap-py3-latest.tar.gz
sudo cp /opt/aws/bin/cfn-hup /etc/init.d/cfn-hup
sudo chmod +x /etc/init.d/cfn-hup
sudo update-rc.d cfn-hup defaults
