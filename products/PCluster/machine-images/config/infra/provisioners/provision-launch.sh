#!/bin/bash
cd /home/ec2-user
p=$(pwd)
echo "You are currently in: $p"
sudo yum update -y
sudo yum install -y jq git gcc-c++ make curl awscli unzip
# Install yq
sudo wget -qO /usr/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod a+x /usr/bin/yq
# Install Virtual Env
python3 -m pip install --upgrade pip
python3 -m pip install --user --upgrade virtualenv
python3 -m virtualenv /home/ec2-user/apc-ve
source /home/ec2-user/apc-ve/bin/activate
# Install Node
curl -sL https://rpm.nodesource.com/setup_16.x | sudo -E bash -
sudo yum install -y nodejs
# Install PCluster
python3 -m pip install --upgrade "aws-parallelcluster"
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
p=$(pwd)
echo "You are currently in: $p"
cd /home/ec2-user
mkdir -p /home/ec2-user/parallel-update
cp /tmp/cluster/* /home/ec2-user/parallel-update/
sudo chown -R ec2-user:ec2-user /home/ec2-user/*
chmod 775  parallel-update/slurm.yaml
chmod 775  parallel-update/batch.yaml
chmod 775  parallel-update/Provision-pcluster.sh
chmod 777  parallel-update/postinstall.sh
chmod 777  parallel-update/sample.sh
rm -rf /tmp/PCluster
rm -rf /tmp/cluster
