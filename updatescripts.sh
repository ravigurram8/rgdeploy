#!/bin/bash
# Download the latest scripts
aws s3 cp s3://rg-deployment-docs/scripts.tar.gz /home/ubuntu
mkdir -p /home/ubuntu/scripts
tar -xvf /home/ubuntu/scripts.tar.gz -C /home/ubuntu/scripts

grep -i version /usr/local/sbin/fix*.sh /usr/local/sbin/start_server.sh
# Check if any of the scripts are later versions than those present
# in the AMI
if [ ! -f /usr/local/sbin/fixips.sh ] ||  [ /home/ubuntu/scripts/fixips.sh -nt /usr/local/sbin/fixips.sh ]; then
  echo "Found newer version of fixips.sh. Updating"
  cp /home/ubuntu/scripts/fixips.sh  /usr/local/sbin/
fi

if [ ! -f /home/ubuntu/scripts/fixmongo.sh ] ||  [ /home/ubuntu/scripts/fixmongo.sh -nt /usr/local/sbin/fixmongo.sh ]; then
  echo "Found newer version of fixmongo.sh. Updating"
  cp /home/ubuntu/scripts/fixmongo.sh  /usr/local/sbin/
fi

if [ ! -f /usr/local/sbin/fixconfigs.sh ] ||  [ /home/ubuntu/scripts/fixconfigs.sh -nt /usr/local/sbin/fixconfigs.sh ]; then
  echo "Found newer version of fixconfigs.sh. Updating"
  cp /home/ubuntu/scripts/fixconfigs.sh  /usr/local/sbin/
fi

if [ ! -f /usr/local/sbin/fixdocdb.sh ] ||  [ /home/ubuntu/scripts/fixdocdb.sh -nt /usr/local/sbin/fixdocdb.sh ]; then
  echo "Found newer version of fixdocdb.sh. Updating"
  cp /home/ubuntu/scripts/fixdocdb.sh  /usr/local/sbin/
fi

if [ ! -f /usr/local/sbin/fixsecrets.sh ] ||  [ /home/ubuntu/scripts/fixsecrets.sh -nt /usr/local/sbin/fixsecrets.sh ]; then
  echo "Found newer version of fixsecrets.sh. Updating"
  cp /home/ubuntu/scripts/fixsecrets.sh  /usr/local/sbin/
fi

if [ ! -f /usr/local/sbin/fixswarm.sh ] ||  [ /home/ubuntu/scripts/fixswarm.sh -nt /usr/local/sbin/fixswarm.sh ]; then
  echo "Found newer version of fixswarm.sh. Updating"
  cp /home/ubuntu/scripts/fixswarm.sh  /usr/local/sbin/
fi

if [ ! -f /usr/local/sbin/start_server.sh ] ||  [ /home/ubuntu/scripts/start_server.sh -nt /usr/local/sbin/start_server.sh ]; then
  echo "Found newer version of start_server.sh. Updating"
  cp /home/ubuntu/scripts/start_server.sh  /usr/local/sbin/
fi
grep -i version /usr/local/sbin/fix*.sh /usr/local/sbin/start_server.sh
rm -rf /home/ubuntu/scripts
echo "Done updating scripts"
